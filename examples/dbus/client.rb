#!/usr/bin/env ruby
# frozen_string_literal: true

require 'bundler/setup'

require 'nio'
require 'toyrpc/dbus'

module Factory
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

class MyProxy < ToyRPC::DBus::BasicProxy
  include Factory

  def greeting
    message = greeting_message bus.unique_name

    bus.send_async message do |_return_message, result|
      yield String(Array(result).first)
    end
  end

  def add(left, right)
    message = add_message bus.unique_name, left, right

    bus.send_async message do |_return_message, result|
      yield Integer(Array(result).first)
    end
  end

  def sub(left, right)
    message = sub_message bus.unique_name, left, right

    bus.send_async message do |_return_message, result|
      yield Integer(Array(result).first)
    end
  end

  def mul(left, right)
    message = mul_message bus.unique_name, left, right

    bus.send_async message do |_return_message, result|
      yield Integer(Array(result).first)
    end
  end

  def hello(name)
    message = hello_message bus.unique_name, name

    bus.send_async message do |_return_message, result|
      yield String(Array(result).first)
    end
  end
end

class OtherProxy < ToyRPC::DBus::BasicProxy
  include Factory

  def full_name(first_name, last_name)
    message = full_name_message bus.unique_name, first_name, last_name

    bus.send_async message do |_return_message, result|
      yield String(Array(result).first)
    end
  end
end

dbus_manager = ToyRPC::DBus::Manager.new

dbus_manager.connect :session
dbus_manager.connect :custom, ARGV[0]

dbus_manager[:session].add_proxy_class :my,    MyProxy
dbus_manager[:custom].add_proxy_class  :other, OtherProxy

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

dbus_manager[:session].proxy(:my).greeting do |result|
  counter += 1
  raise unless result == 'Hello!'
end

dbus_manager[:session].proxy(:my).add(1, 1) do |result|
  counter += 1
  raise unless result == 2
end

dbus_manager[:session].proxy(:my).sub(2, 3) do |result|
  counter += 1
  raise unless result == -1
end

dbus_manager[:session].proxy(:my).mul(3, 5) do |result|
  counter += 1
  raise unless result == 15
end

dbus_manager[:session].proxy(:my).hello('Alex') do |result|
  counter += 1
  raise unless result == 'Hello, Alex!'
end

dbus_manager[:custom].proxy(:other).full_name('Alex', 'Kotov') do |result|
  counter += 1
  raise unless result == 'Alex Kotov'
end

while counter < 6
  selector.select do |monitor|
    monitor.value.call
  end
end

puts 'ok!'
