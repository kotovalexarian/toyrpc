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

  def do_hello(name)
    "Hello, #{name}!"
  end

  def do_full_name(first_name, last_name)
    "#{first_name} #{last_name}"
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

INTERFACES2 = {
  'com.example.Helloable': ToyRPC::DBus::Interface.new(
    name:    :'com.example.Helloable',
    signals: {}.freeze,
    methods: {
      hello: ToyRPC::DBus::Method.new(
        name: :hello,
        to:   :do_hello,
        ins:  [
          ToyRPC::DBus::Param.new(name: :name, direction: :in, type: :s),
        ],
        outs: [
          ToyRPC::DBus::Param.new(name: :result, direction: :out, type: :s),
        ],
      ),
    }.freeze,
  ),
}.freeze

INTERFACES3 = {
  'com.example.Nameable': ToyRPC::DBus::Interface.new(
    name:    :'com.example.Nameable',
    signals: {}.freeze,
    methods: {
      full_name: ToyRPC::DBus::Method.new(
        name: :full_name,
        to:   :do_full_name,
        ins:  [
          ToyRPC::DBus::Param.new(name: :first_name, direction: :in, type: :s),
          ToyRPC::DBus::Param.new(name: :last_name,  direction: :in, type: :s),
        ],
        outs: [
          ToyRPC::DBus::Param.new(name: :result, direction: :out, type: :s),
        ],
      ),
    }.freeze,
  ),
}.freeze

my_handler = MyHandler.new

dbus_connection_pool = ToyRPC::DBus::ConnectionPool.new

dbus_bus1 = dbus_connection_pool.connect :session
dbus_bus2 = dbus_connection_pool.connect ARGV[0]

dbus_service1 = dbus_bus1.request_service 'com.example.MyHandler1'
dbus_service2 = dbus_bus1.request_service 'com.example.MyHandler2'
dbus_service3 = dbus_bus2.request_service 'com.example.MyHandler3'

dbus_object1 = ToyRPC::DBus::Object.new(
  '/com/example/MyHandler1',
  my_handler,
  INTERFACES1,
)

dbus_object2 = ToyRPC::DBus::Object.new(
  '/com/example/MyHandler2',
  my_handler,
  INTERFACES2,
)

dbus_object3 = ToyRPC::DBus::Object.new(
  '/com/example/MyHandler3',
  my_handler,
  INTERFACES3,
)

dbus_service1.export dbus_object1
dbus_service2.export dbus_object2
dbus_service3.export dbus_object3

event_loop = ToyRPC::DBus::EventLoop.new

dbus_connection_pool.buses.each do |dbus_bus|
  event_loop << dbus_bus
end

event_loop.run
