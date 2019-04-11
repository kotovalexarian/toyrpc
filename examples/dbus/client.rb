#!/usr/bin/env ruby
# frozen_string_literal: true

require 'bundler/setup'

require 'nio'
require 'toyrpc/dbus'

module Factory
module_function

  def greeting_message(sender)
    ::DBus::Message.new(::DBus::Message::METHOD_CALL).tap do |m|
      m.sender      = sender
      m.destination = 'com.example.MyHandler1'
      m.path        = '/com/example/MyHandler1'
      m.interface   = 'com.example.Greetable'
      m.member      = 'greeting'
    end
  end

  def add_message(sender, left, right)
    ::DBus::Message.new(::DBus::Message::METHOD_CALL).tap do |m|
      m.sender      = sender
      m.destination = 'com.example.MyHandler1'
      m.path        = '/com/example/MyHandler1'
      m.interface   = 'com.example.Calculable'
      m.member      = 'add'

      m.add_param 'i', Integer(left)
      m.add_param 'i', Integer(right)
    end
  end

  def sub_message(sender, left, right)
    ::DBus::Message.new(::DBus::Message::METHOD_CALL).tap do |m|
      m.sender      = sender
      m.destination = 'com.example.MyHandler1'
      m.path        = '/com/example/MyHandler1'
      m.interface   = 'com.example.Calculable'
      m.member      = 'sub'

      m.add_param 'i', Integer(left)
      m.add_param 'i', Integer(right)
    end
  end

  def mul_message(sender, left, right)
    ::DBus::Message.new(::DBus::Message::METHOD_CALL).tap do |m|
      m.sender      = sender
      m.destination = 'com.example.MyHandler1'
      m.path        = '/com/example/MyHandler1'
      m.interface   = 'com.example.Calculable'
      m.member      = 'mul'

      m.add_param 'i', Integer(left)
      m.add_param 'i', Integer(right)
    end
  end

  def hello_message(sender, name)
    ::DBus::Message.new(::DBus::Message::METHOD_CALL).tap do |m|
      m.sender      = sender
      m.destination = 'com.example.MyHandler2'
      m.path        = '/com/example/MyHandler2'
      m.interface   = 'com.example.Helloable'
      m.member      = 'hello'

      m.add_param 's', String(name)
    end
  end

  def full_name_message(sender, first_name, last_name)
    ::DBus::Message.new(::DBus::Message::METHOD_CALL).tap do |m|
      m.sender      = sender
      m.destination = 'com.example.MyHandler3'
      m.path        = '/com/example/MyHandler3'
      m.interface   = 'com.example.Nameable'
      m.member      = 'full_name'

      m.add_param 's', String(first_name)
      m.add_param 's', String(last_name)
    end
  end
end

dbus_manager = ToyRPC::DBus::Manager.new

dbus_manager.connect :session
dbus_manager.connect :custom, ARGV[0]

###########
# IO code #
###########

selector = NIO::Selector.new

dbus_manager.gateways.each do |dbus_gateway|
  bus           = dbus_gateway.bus
  message_queue = bus.message_queue

  monitor = selector.register message_queue, :rw

  monitor.value = lambda do
    begin
      message_queue.flush_write_buffer
    rescue IO::WaitWritable
      nil
    end

    begin
      message_queue.flush_read_buffer
    rescue IO::WaitReadable
      return
    end

    while (message = message_queue.read_message)
      bus.process message
    end
  rescue EOFError, SystemCallError
    selector.deregister message_queue
  end
end

counter = 0

dbus_manager[:session].bus.tap do |bus|
  message = Factory.greeting_message bus.unique_name

  bus.send_async message do |_return_message, result|
    counter += 1
    raise unless result == 'Hello!'
  end
end

dbus_manager[:session].bus.tap do |bus|
  message = Factory.add_message bus.unique_name, 1, 2

  bus.send_async message do |_return_message, result|
    counter += 1
    raise unless result == 3
  end
end

dbus_manager[:session].bus.tap do |bus|
  message = Factory.sub_message bus.unique_name, 2, 3

  bus.send_async message do |_return_message, result|
    counter += 1
    raise unless result == -1
  end
end

dbus_manager[:session].bus.tap do |bus|
  message = Factory.mul_message bus.unique_name, 3, 5

  bus.send_async message do |_return_message, result|
    counter += 1
    raise unless result == 15
  end
end

dbus_manager[:session].bus.tap do |bus|
  message = Factory.hello_message bus.unique_name, 'Alex'

  bus.send_async message do |_return_message, result|
    counter += 1
    raise unless result == 'Hello, Alex!'
  end
end

dbus_manager[:custom].bus.tap do |bus|
  message = Factory.full_name_message bus.unique_name, 'Alex', 'Kotov'

  bus.send_async message do |_return_message, result|
    counter += 1
    raise unless result == 'Alex Kotov'
  end
end

while counter < 6
  selector.select do |monitor|
    monitor.value.call
  end
end

puts 'ok!'
