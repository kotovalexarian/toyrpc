#!/usr/bin/env ruby
# frozen_string_literal: true

require 'bundler/setup'

require 'toyrpc/dbus'

class QueueObject
  def initialize(dbus_manager)
    @dbus_manager = dbus_manager
  end

  def pop
    call_message = ::DBus::Message.new ::DBus::Message::METHOD_CALL
    call_message.sender = custom_bus.unique_name
    call_message.destination = 'com.example.Queue'
    call_message.path = '/com/example/Queue'
    call_message.interface = 'com.example.Queue'
    call_message.member = 'pop'

    result = custom_bus.send_sync_or_async(call_message)

    String(Array(result).first)
  end

private

  attr_reader :dbus_manager

  def custom_bus
    @custom_bus ||= dbus_manager[:custom].bus
  end
end

dbus_manager = ToyRPC::DBus::Manager.new

dbus_manager.connect :custom, ARGV[0]

queue_object = QueueObject.new dbus_manager

loop do
  value = queue_object.pop

  unless value.empty?
    puts value
    sleep 0.1
    next
  end

  sleep 1
end
