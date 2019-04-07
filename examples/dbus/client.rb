#!/usr/bin/env ruby
# frozen_string_literal: true

require 'dbus'

class MyObject
  def initialize(dbus_bus)
    @dbus_bus = dbus_bus
  end

  def greeting
    greeting_dbus_interface.greeting
  end

  def add(left, right)
    calculable_dbus_interface.add(left, right)
  end

  def sub(left, right)
    calculable_dbus_interface.sub(left, right)
  end

  def mul(left, right)
    calculable_dbus_interface.mul(left, right)
  end

private

  attr_reader :dbus_bus

  def dbus_service1
    @dbus_service ||= dbus_bus['com.example.MyHandler1']
  end

  def dbus_object1
    @dbus_object ||= dbus_service1['/com/example/MyHandler1']
  end

  def greeting_dbus_interface
    @greeting_dbus_interface ||= dbus_object1['com.example.Greetable']
  end

  def calculable_dbus_interface
    @calculable_dbus_interface ||= dbus_object1['com.example.Calculable']
  end
end

dbus_socket_name = ARGV[0].to_s.strip

dbus_bus = if dbus_socket_name.empty?
             DBus.session_bus
           else
             DBus::RemoteBus.new dbus_socket_name
           end

my_object = MyObject.new dbus_bus

raise unless my_object.greeting == 'Hello!'
raise unless my_object.add(1, 1) == 2
raise unless my_object.sub(2, 3) == -1
raise unless my_object.mul(3, 5) == 15

puts 'ok!'
