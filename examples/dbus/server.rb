#!/usr/bin/env ruby
# frozen_string_literal: true

require 'bundler/setup'

require 'toyrpc/dbus'

class MyHandler
  def do_greeting
    'Hello!'
  end

  def do_add(left, right)
    left + right
  end

  def do_sub(left, right)
    left - right
  end

  def do_mul(left, right)
    left * right
  end
end

INTERFACES1 = {
  'com.example.Greetable':  ToyRPC::DBus::Interface.new(
    name:    :'com.example.Greetable',
    signals: {}.freeze,
    methods: {
      greeting: ToyRPC::DBus::Method.new(
        name: :greeting,
        to:   :do_greeting,
        ins:  [],
        outs: [
          ToyRPC::DBus::Param.new(name: :result, direction: :out, type: :s),
        ],
      ).freeze,
    }.freeze,
  ).freeze,

  'com.example.Calculable': ToyRPC::DBus::Interface.new(
    name:    :'com.example.Calculable',
    signals: {}.freeze,
    methods: {
      add: ToyRPC::DBus::Method.new(
        name: :add,
        to:   :do_add,
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
        to:   :do_sub,
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
        to:   :do_mul,
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

dbus_service1 = dbus_bus.request_service 'com.example.MyHandler1'

dbus_object1 = ToyRPC::DBus::Object.new(
  '/com/example/MyHandler1',
  my_handler,
  INTERFACES1,
)

dbus_service1.export dbus_object1

dbus_main = DBus::Main.new
dbus_main << dbus_bus
dbus_main.run
