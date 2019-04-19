#!/usr/bin/env ruby
# frozen_string_literal: true

require 'bundler/setup'

require 'nio'
require 'toyrpc/dbus'

module Factory
module_function # rubocop:disable Layout/IndentationWidth

  def greeting_message(sender)
    ToyRPC::DBus::Message.method_call(
      sender,
      'com.example.MyHandler1',
      '/com/example/MyHandler1',
      'com.example.Greetable',
      'greeting',
    )
  end

  def add_message(sender, left, right)
    ToyRPC::DBus::Message.method_call(
      sender,
      'com.example.MyHandler1',
      '/com/example/MyHandler1',
      'com.example.Calculable',
      'add',
      ['i', Integer(left)],
      ['i', Integer(right)],
    )
  end

  def sub_message(sender, left, right)
    ToyRPC::DBus::Message.method_call(
      sender,
      'com.example.MyHandler1',
      '/com/example/MyHandler1',
      'com.example.Calculable',
      'sub',
      ['i', Integer(left)],
      ['i', Integer(right)],
    )
  end

  def mul_message(sender, left, right)
    ToyRPC::DBus::Message.method_call(
      sender,
      'com.example.MyHandler1',
      '/com/example/MyHandler1',
      'com.example.Calculable',
      'mul',
      ['i', Integer(left)],
      ['i', Integer(right)],
    )
  end

  def hello_message(sender, name)
    ToyRPC::DBus::Message.method_call(
      sender,
      'com.example.MyHandler2',
      '/com/example/MyHandler2',
      'com.example.Helloable',
      'hello',
      ['s', String(name)],
    )
  end

  def full_name_message(sender, first_name, last_name)
    ToyRPC::DBus::Message.method_call(
      sender,
      'com.example.MyHandler3',
      '/com/example/MyHandler3',
      'com.example.Nameable',
      'full_name',
      ['s', String(first_name)],
      ['s', String(last_name)],
    )
  end
end

dbus_manager = ToyRPC::DBus::Manager.new

dbus_manager.connect :session
dbus_manager.connect :custom, ARGV[0]

###########
# IO code #
###########

selector = NIO::Selector.new

dbus_manager.buses.each do |bus|
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

dbus_manager[:session].tap do |bus|
  message = Factory.greeting_message bus.unique_name

  bus.send_async message do |_return_message, result|
    counter += 1
    raise unless result == 'Hello!'
  end
end

dbus_manager[:session].tap do |bus|
  message = Factory.add_message bus.unique_name, 1, 2

  bus.send_async message do |_return_message, result|
    counter += 1
    raise unless result == 3
  end
end

dbus_manager[:session].tap do |bus|
  message = Factory.sub_message bus.unique_name, 2, 3

  bus.send_async message do |_return_message, result|
    counter += 1
    raise unless result == -1
  end
end

dbus_manager[:session].tap do |bus|
  message = Factory.mul_message bus.unique_name, 3, 5

  bus.send_async message do |_return_message, result|
    counter += 1
    raise unless result == 15
  end
end

dbus_manager[:session].tap do |bus|
  message = Factory.hello_message bus.unique_name, 'Alex'

  bus.send_async message do |_return_message, result|
    counter += 1
    raise unless result == 'Hello, Alex!'
  end
end

dbus_manager[:custom].tap do |bus|
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
