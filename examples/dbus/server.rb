#!/usr/bin/env ruby
# frozen_string_literal: true

require 'dbus'

class MyHandler
  def add(left, right)
    left + right
  end

  def sub(left, right)
    left - right
  end

  def mul(left, right)
    left * right
  end
end

my_handler = MyHandler.new

class MyHandlerDBusObject < DBus::Object
  attr_reader :my_handler

  def initialize(*args, my_handler)
    super(*args)
    @my_handler = my_handler
  end

  dbus_interface 'com.example.MyHandler' do
    dbus_method :add, 'in left:i, in right:i, out result:i' do |left, right|
      my_handler.add(left, right)
    end

    dbus_method :sub, 'in left:i, in right:i, out result:i' do |left, right|
      my_handler.sub(left, right)
    end

    dbus_method :mul, 'in left:i, in right:i, out result:i' do |left, right|
      my_handler.mul(left, right)
    end
  end
end

dbus_socket_name = ARGV[0].to_s.strip

dbus_bus = if dbus_socket_name.empty?
             DBus.session_bus
           else
             DBus::RemoteBus.new dbus_socket_name
           end

dbus_service = dbus_bus.request_service 'com.example.MyHandler'

dbus_object = MyHandlerDBusObject.new '/com/example/MyHandler', my_handler

dbus_service.export dbus_object

dbus_main = DBus::Main.new
dbus_main << dbus_bus
dbus_main.run
