#!/usr/bin/env ruby
# frozen_string_literal: true

require 'bundler/setup'

require 'toyrpc/dbus'

class QueueProxy
  def initialize(bus)
    self.bus = bus
  end

  def pop
    call_message = ::DBus::Message.new ::DBus::Message::METHOD_CALL
    call_message.sender = bus.unique_name
    call_message.destination = 'com.example.Queue'
    call_message.path = '/com/example/Queue'
    call_message.interface = 'com.example.Queue'
    call_message.member = 'pop'

    result = bus.send_sync_or_async(call_message)

    String(Array(result).first)
  end

private

  attr_reader :bus

  def bus=(value)
    unless value.instance_of? ToyRPC::DBus::Bus
      raise TypeError, "Expected #{ToyRPC::DBus::Bus}, got #{value.class}"
    end

    @bus = value
  end
end

dbus_manager = ToyRPC::DBus::Manager.new

dbus_manager.connect :custom, ARGV[0]

queue_proxy = QueueProxy.new dbus_manager[:custom].bus

loop do
  value = queue_proxy.pop

  unless value.empty?
    puts value
    sleep 0.1
    next
  end

  sleep 1
end
