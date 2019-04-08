#!/usr/bin/env ruby
# frozen_string_literal: true

require 'bundler/setup'

require 'securerandom'
require 'toyrpc/dbus'

class QueueProxy < ToyRPC::DBus::BasicProxy
  def push(str)
    call_message = ::DBus::Message.new ::DBus::Message::METHOD_CALL
    call_message.sender = bus.unique_name
    call_message.destination = 'com.example.Queue'
    call_message.path = '/com/example/Queue'
    call_message.interface = 'com.example.Queue'
    call_message.member = 'push'
    call_message.add_param 's', str

    bus.send_sync_or_async(call_message)

    nil
  end
end

dbus_manager = ToyRPC::DBus::Manager.new

dbus_manager.connect :session

dbus_manager[:session].add_proxy_class :queue, QueueProxy

loop do
  dbus_manager[:session].proxy(:queue).push SecureRandom.hex
  sleep 1
end
