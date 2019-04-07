#!/usr/bin/env ruby
# frozen_string_literal: true

require 'bundler/setup'

require 'toyrpc/dbus'

class MyObject
  def initialize(dbus_bus1, dbus_bus2)
    @dbus_bus1 = dbus_bus1
    @dbus_bus2 = dbus_bus2
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

  def hello(name)
    helloable_dbus_interface.hello(name)
  end

  def full_name(first_name, last_name)
    nameable_dbus_interface.full_name(first_name, last_name)
  end

private

  attr_reader :dbus_bus1, :dbus_bus2

  def dbus_service1
    @dbus_service1 ||= dbus_bus1['com.example.MyHandler1']
  end

  def dbus_service2
    @dbus_service2 ||= dbus_bus1['com.example.MyHandler2']
  end

  def dbus_service3
    @dbus_service3 ||= dbus_bus2['com.example.MyHandler3']
  end

  def dbus_object1
    @dbus_object1 ||= dbus_service1['/com/example/MyHandler1']
  end

  def dbus_object2
    @dbus_object2 ||= dbus_service2['/com/example/MyHandler2']
  end

  def dbus_object3
    @dbus_object3 ||= dbus_service3['/com/example/MyHandler3']
  end

  def greeting_dbus_interface
    @greeting_dbus_interface ||= dbus_object1['com.example.Greetable']
  end

  def calculable_dbus_interface
    @calculable_dbus_interface ||= dbus_object1['com.example.Calculable']
  end

  def helloable_dbus_interface
    @helloable_dbus_interface ||= dbus_object2['com.example.Helloable']
  end

  def nameable_dbus_interface
    @nameable_dbus_interface ||= dbus_object3['com.example.Nameable']
  end
end

dbus_manager = ToyRPC::DBus::Manager.new

dbus_manager.connect :session
dbus_manager.connect :custom, ARGV[0]

my_object = MyObject.new dbus_manager[:session].bus, dbus_manager[:custom].bus

raise unless my_object.greeting == 'Hello!'
raise unless my_object.add(1, 1) == 2
raise unless my_object.sub(2, 3) == -1
raise unless my_object.mul(3, 5) == 15
raise unless my_object.hello('Alex') == 'Hello, Alex!'
raise unless my_object.full_name('Alex', 'Kotov') == 'Alex Kotov'

puts 'ok!'
