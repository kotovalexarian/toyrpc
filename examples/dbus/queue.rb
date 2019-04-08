#!/usr/bin/env ruby
# frozen_string_literal: true

require 'bundler/setup'

require 'toyrpc/dbus'

class QueueHandler
  INTROSPECT = File.read(File.expand_path('queue.xml', __dir__)).freeze

  def initialize
    @queue = []
  end

  def introspect
    INTROSPECT
  end

  def push(str)
    @queue << str
    nil
  end

  def pop
    @queue.shift || ''
  end
end

INTERFACES = {
  'org.freedesktop.DBus.Introspectable': ToyRPC::DBus::Interface.new(
    name:    :'org.freedesktop.DBus.Introspectable',
    signals: {},
    methods: {
      Introspect: ToyRPC::DBus::Method.new(
        name: :Introspect,
        to:   :introspect,
        ins:  [],
        outs: [
          ToyRPC::DBus::Param.new(name: :str, direction: :out, type: :s),
        ],
      ),
    },
  ),

  'com.example.Queue':                   ToyRPC::DBus::Interface.new(
    name:    :'com.example.Queue',
    signals: {},
    methods: {
      push: ToyRPC::DBus::Method.new(
        name: :push,
        to:   :push,
        ins:  [
          ToyRPC::DBus::Param.new(name: :str, direction: :in, type: :s),
        ],
        outs: [],
      ),
      pop:  ToyRPC::DBus::Method.new(
        name: :pop,
        to:   :pop,
        ins:  [],
        outs: [
          ToyRPC::DBus::Param.new(name: :str, direction: :out, type: :s),
        ],
      ),
    },
  ),
}.freeze

def request_service(dbus_gateway, service_name)
  dbus_gateway.proxy(:dbus).request_name(
    service_name,
    ::DBus::Connection::NAME_FLAG_REPLACE_EXISTING,
  ) do |return_message, r|
    raise return_message if return_message.is_a? ::DBus::Error
    unless r == ::DBus::Connection::REQUEST_NAME_REPLY_PRIMARY_OWNER
      raise ::DBus::Connection::NameRequestError
    end
  end
end

queue_handler = QueueHandler.new

dbus_manager = ToyRPC::DBus::Manager.new queue_handler, INTERFACES

dbus_manager.connect :session

ARGV.each_with_index do |socket_name, index|
  dbus_manager.connect :"nr_#{index}", socket_name
end

dbus_manager.gateways.each do |dbus_gateway|
  dbus_gateway.add_proxy_class :dbus, ToyRPC::DBus::DBusProxy
end

dbus_manager.gateways.map do |dbus_gateway|
  request_service dbus_gateway, 'com.example.Queue'
end

event_loop = ToyRPC::DBus::EventLoop.new

dbus_manager.gateways.each do |dbus_gateway|
  event_loop << dbus_gateway.bus
end

event_loop.run
