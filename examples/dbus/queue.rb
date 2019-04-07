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
    @queue.shift
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

queue_handler = QueueHandler.new

dbus_buses = [ToyRPC::DBus.bus(ToyRPC::DBus.session_socket_name)]

ARGV.each do |socket_name|
  dbus_buses << ToyRPC::DBus.bus(socket_name)
end

dbus_services = dbus_buses.map do |dbus_bus|
  dbus_bus.request_service 'com.example.Queue'
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

dbus_buses.each do |dbus_bus|
  event_loop << dbus_bus
end

event_loop.run
