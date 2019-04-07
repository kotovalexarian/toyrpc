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

dbus_manager = ToyRPC::DBus::Manager.new

dbus_manager.connect :session

ARGV.each_with_index do |socket_name, index|
  dbus_manager.connect :"nr_#{index}", socket_name
end

dbus_services = dbus_manager.gateways.map do |dbus_gateway|
  dbus_gateway.bus.request_service 'com.example.Queue'
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
