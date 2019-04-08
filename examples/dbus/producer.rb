#!/usr/bin/env ruby
# frozen_string_literal: true

require 'bundler/setup'

require 'securerandom'
require 'toyrpc/dbus'

class QueueObject
  def initialize(dbus_manager)
    @dbus_manager = dbus_manager
  end

  def push(str)
    call_message = ::DBus::Message.new ::DBus::Message::METHOD_CALL
    call_message.sender = session_bus.unique_name
    call_message.destination = 'com.example.Queue'
    call_message.path = '/com/example/Queue'
    call_message.interface = 'com.example.Queue'
    call_message.member = 'push'
    call_message.add_param 's', str

    session_bus.send_sync_or_async(call_message)

    nil
  end

private

  attr_reader :dbus_manager

  def session_bus
    @session_bus ||= dbus_manager[:session].bus
  end
end

dbus_manager = ToyRPC::DBus::Manager.new

dbus_manager.connect :session

queue_object = QueueObject.new dbus_manager

loop do
  queue_object.push SecureRandom.hex
  sleep 1
end
