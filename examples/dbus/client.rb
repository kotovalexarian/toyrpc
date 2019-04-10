#!/usr/bin/env ruby
# frozen_string_literal: true

require 'bundler/setup'

require 'nio'
require 'toyrpc/dbus'

class MyProxy < ToyRPC::DBus::BasicProxy
  def greeting
    call_message = ::DBus::Message.new ::DBus::Message::METHOD_CALL
    call_message.sender = bus.unique_name
    call_message.destination = 'com.example.MyHandler1'
    call_message.path = '/com/example/MyHandler1'
    call_message.interface = 'com.example.Greetable'
    call_message.member = 'greeting'

    bus.send_async call_message do |_return_message, result|
      yield String(Array(result).first)
    end
  end

  def add(left, right)
    call_message = ::DBus::Message.new ::DBus::Message::METHOD_CALL
    call_message.sender = bus.unique_name
    call_message.destination = 'com.example.MyHandler1'
    call_message.path = '/com/example/MyHandler1'
    call_message.interface = 'com.example.Calculable'
    call_message.member = 'add'
    call_message.add_param 'i', left
    call_message.add_param 'i', right

    bus.send_async call_message do |_return_message, result|
      yield Integer(Array(result).first)
    end
  end

  def sub(left, right)
    call_message = ::DBus::Message.new ::DBus::Message::METHOD_CALL
    call_message.sender = bus.unique_name
    call_message.destination = 'com.example.MyHandler1'
    call_message.path = '/com/example/MyHandler1'
    call_message.interface = 'com.example.Calculable'
    call_message.member = 'sub'
    call_message.add_param 'i', left
    call_message.add_param 'i', right

    bus.send_async call_message do |_return_message, result|
      yield Integer(Array(result).first)
    end
  end

  def mul(left, right)
    call_message = ::DBus::Message.new ::DBus::Message::METHOD_CALL
    call_message.sender = bus.unique_name
    call_message.destination = 'com.example.MyHandler1'
    call_message.path = '/com/example/MyHandler1'
    call_message.interface = 'com.example.Calculable'
    call_message.member = 'mul'
    call_message.add_param 'i', left
    call_message.add_param 'i', right

    bus.send_async call_message do |_return_message, result|
      yield Integer(Array(result).first)
    end
  end

  def hello(name)
    call_message = ::DBus::Message.new ::DBus::Message::METHOD_CALL
    call_message.sender = bus.unique_name
    call_message.destination = 'com.example.MyHandler2'
    call_message.path = '/com/example/MyHandler2'
    call_message.interface = 'com.example.Helloable'
    call_message.member = 'hello'
    call_message.add_param 's', name

    bus.send_async call_message do |_return_message, result|
      yield String(Array(result).first)
    end
  end
end

class OtherProxy < ToyRPC::DBus::BasicProxy
  def full_name(first_name, last_name)
    call_message = ::DBus::Message.new ::DBus::Message::METHOD_CALL
    call_message.sender = bus.unique_name
    call_message.destination = 'com.example.MyHandler3'
    call_message.path = '/com/example/MyHandler3'
    call_message.interface = 'com.example.Nameable'
    call_message.member = 'full_name'
    call_message.add_param 's', first_name
    call_message.add_param 's', last_name

    bus.send_async call_message do |_return_message, result|
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
    message_queue.buffer_to_socket_nonblock

    message_queue.buffer_from_socket_nonblock

    while (message = message_queue.message_from_buffer_nonblock)
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
