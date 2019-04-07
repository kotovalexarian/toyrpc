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
    dbus_iface.push(str)
  end

  def pop
    dbus_iface.pop
  end

private

  attr_reader :dbus_manager

  def dbus_iface
    @dbus_iface ||=
      dbus_manager[:session]
      .bus['com.example.Queue']['/com/example/Queue']['com.example.Queue']
  end
end

dbus_manager = ToyRPC::DBus::Manager.new

dbus_manager.connect :session

queue_object = QueueObject.new dbus_manager

loop do
  queue_object.push SecureRandom.hex
  sleep 1
end
