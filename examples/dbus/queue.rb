#!/usr/bin/env ruby
# frozen_string_literal: true

require 'bundler/setup'

require 'toyrpc/dbus'

class QueueHandler
  def initialize
    @queue = []
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
  'com.example.Queue': ToyRPC::DBus::Interface.new(
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

  dbus_gateway.bus.add_service service_name
end

queue_handler = QueueHandler.new

dbus_manager = ToyRPC::DBus::Manager.new

dbus_manager.connect :session

ARGV.each_with_index do |socket_name, index|
  dbus_manager.connect :"nr_#{index}", socket_name
end

dbus_manager.gateways.each do |dbus_gateway|
  dbus_gateway.add_proxy_class :dbus, ToyRPC::DBus::DBusProxy
end

dbus_services = dbus_manager.gateways.map do |dbus_gateway|
  request_service dbus_gateway, 'com.example.Queue'
end

dbus_services.each do |dbus_service|
  dbus_service.export(
    ToyRPC::DBus::Object.new(
      '/com/example/Queue',
      queue_handler,
      INTERFACES,
    ),
  )
end

event_loop = ToyRPC::DBus::EventLoop.new

dbus_manager.gateways.each do |dbus_gateway|
  event_loop << dbus_gateway.bus
end

event_loop.run
