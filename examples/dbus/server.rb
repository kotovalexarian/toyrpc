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

def request_service(dbus_manager, gateway_name, service_name)
  dbus_manager[gateway_name].proxy(:dbus).request_name(
    service_name,
    ::DBus::Connection::NAME_FLAG_REPLACE_EXISTING,
  ) do |return_message, r|
    raise return_message if return_message.is_a? ::DBus::Error
    unless r == ::DBus::Connection::REQUEST_NAME_REPLY_PRIMARY_OWNER
      raise ::DBus::Connection::NameRequestError
    end
  end

  dbus_manager[gateway_name].bus.add_service service_name
end

my_handler = MyHandler.new

dbus_manager = ToyRPC::DBus::Manager.new

dbus_manager.connect :session
dbus_manager.connect :custom, ARGV[0]

dbus_manager[:session].add_proxy_class :dbus, ToyRPC::DBus::DBusProxy
dbus_manager[:custom].add_proxy_class  :dbus, ToyRPC::DBus::DBusProxy

dbus_service1 = request_service dbus_manager, :session, 'com.example.MyHandler1'
dbus_service2 = request_service dbus_manager, :session, 'com.example.MyHandler2'
dbus_service3 = request_service dbus_manager, :custom,  'com.example.MyHandler3'

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

dbus_manager.gateways.each do |dbus_gateway|
  event_loop << dbus_gateway.bus
end

event_loop.run
