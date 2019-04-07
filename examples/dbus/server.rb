#!/usr/bin/env ruby
# frozen_string_literal: true

require 'bundler/setup'

require 'toyrpc/dbus'

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

INTERFACES = {
  'com.example.MyHandler': ToyRPC::DBus::Interface.new(
    name:    :'com.example.MyHandler',
    signals: {}.freeze,
    methods: {
      add: ToyRPC::DBus::Method.new(
        name: :add,
        ins:  [
          ToyRPC::DBus::Param.new(name: :left,  direction: :in, type: :i),
          ToyRPC::DBus::Param.new(name: :right, direction: :in, type: :i),
        ],
        outs: [
          ToyRPC::DBus::Param.new(name: :result, direction: :out, type: :i),
        ],
      ).freeze,
      sub: ToyRPC::DBus::Method.new(
        name: :sub,
        ins:  [
          ToyRPC::DBus::Param.new(name: :left,  direction: :in, type: :i),
          ToyRPC::DBus::Param.new(name: :right, direction: :in, type: :i),
        ],
        outs: [
          ToyRPC::DBus::Param.new(name: :result, direction: :out, type: :i),
        ],
      ).freeze,
      mul: ToyRPC::DBus::Method.new(
        name: :mul,
        ins:  [
          ToyRPC::DBus::Param.new(name: :left,  direction: :in, type: :i),
          ToyRPC::DBus::Param.new(name: :right, direction: :in, type: :i),
        ],
        outs: [
          ToyRPC::DBus::Param.new(name: :result, direction: :out, type: :i),
        ],
      ).freeze,
    }.freeze,
  ).freeze,
}.freeze

my_handler = MyHandler.new

dbus_socket_name = ARGV[0].to_s.strip

dbus_bus = if dbus_socket_name.empty?
             DBus.session_bus
           else
             DBus::RemoteBus.new dbus_socket_name
           end

dbus_service = dbus_bus.request_service 'com.example.MyHandler'

dbus_object = ToyRPC::DBus::Object.new(
  '/com/example/MyHandler',
  my_handler,
  INTERFACES,
)

dbus_service.export dbus_object

dbus_main = DBus::Main.new
dbus_main << dbus_bus
dbus_main.run
