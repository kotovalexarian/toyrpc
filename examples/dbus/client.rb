#!/usr/bin/env ruby
# frozen_string_literal: true

require 'bundler/setup'

require 'toyrpc/dbus'

class MyObject
  def initialize(dbus_manager)
    @dbus_manager = dbus_manager
  end

  def greeting
    call_message = ::DBus::Message.new ::DBus::Message::METHOD_CALL
    call_message.sender = session_bus.unique_name
    call_message.destination = 'com.example.MyHandler1'
    call_message.path = '/com/example/MyHandler1'
    call_message.interface = 'com.example.Greetable'
    call_message.member = 'greeting'

    result = session_bus.send_sync_or_async(call_message)

    String(Array(result).first)
  end

  def add(left, right)
    call_message = ::DBus::Message.new ::DBus::Message::METHOD_CALL
    call_message.sender = session_bus.unique_name
    call_message.destination = 'com.example.MyHandler1'
    call_message.path = '/com/example/MyHandler1'
    call_message.interface = 'com.example.Calculable'
    call_message.member = 'add'
    call_message.add_param 'i', left
    call_message.add_param 'i', right

    result = session_bus.send_sync_or_async(call_message)

    Integer(Array(result).first)
  end

  def sub(left, right)
    call_message = ::DBus::Message.new ::DBus::Message::METHOD_CALL
    call_message.sender = session_bus.unique_name
    call_message.destination = 'com.example.MyHandler1'
    call_message.path = '/com/example/MyHandler1'
    call_message.interface = 'com.example.Calculable'
    call_message.member = 'sub'
    call_message.add_param 'i', left
    call_message.add_param 'i', right

    result = session_bus.send_sync_or_async(call_message)

    Integer(Array(result).first)
  end

  def mul(left, right)
    call_message = ::DBus::Message.new ::DBus::Message::METHOD_CALL
    call_message.sender = session_bus.unique_name
    call_message.destination = 'com.example.MyHandler1'
    call_message.path = '/com/example/MyHandler1'
    call_message.interface = 'com.example.Calculable'
    call_message.member = 'mul'
    call_message.add_param 'i', left
    call_message.add_param 'i', right

    result = session_bus.send_sync_or_async(call_message)

    Integer(Array(result).first)
  end

  def hello(name)
    call_message = ::DBus::Message.new ::DBus::Message::METHOD_CALL
    call_message.sender = session_bus.unique_name
    call_message.destination = 'com.example.MyHandler2'
    call_message.path = '/com/example/MyHandler2'
    call_message.interface = 'com.example.Helloable'
    call_message.member = 'hello'
    call_message.add_param 's', name

    result = session_bus.send_sync_or_async(call_message)

    String(Array(result).first)
  end

  def full_name(first_name, last_name)
    call_message = ::DBus::Message.new ::DBus::Message::METHOD_CALL
    call_message.sender = custom_bus.unique_name
    call_message.destination = 'com.example.MyHandler3'
    call_message.path = '/com/example/MyHandler3'
    call_message.interface = 'com.example.Nameable'
    call_message.member = 'full_name'
    call_message.add_param 's', first_name
    call_message.add_param 's', last_name

    result = custom_bus.send_sync_or_async(call_message)

    String(Array(result).first)
  end

private

  attr_reader :dbus_manager

  def session_bus
    @session_bus ||= dbus_manager[:session].bus
  end

  def custom_bus
    @custom_bus ||= dbus_manager[:custom].bus
  end
end

dbus_manager = ToyRPC::DBus::Manager.new

dbus_manager.connect :session
dbus_manager.connect :custom, ARGV[0]

my_object = MyObject.new dbus_manager

raise unless my_object.greeting == 'Hello!'
raise unless my_object.add(1, 1) == 2
raise unless my_object.sub(2, 3) == -1
raise unless my_object.mul(3, 5) == 15
raise unless my_object.hello('Alex') == 'Hello, Alex!'
raise unless my_object.full_name('Alex', 'Kotov') == 'Alex Kotov'

puts 'ok!'
