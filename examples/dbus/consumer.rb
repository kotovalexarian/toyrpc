#!/usr/bin/env ruby
# frozen_string_literal: true

require 'bundler/setup'

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
      dbus_manager[:custom]
      .bus['com.example.Queue']['/com/example/Queue']['com.example.Queue']
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
