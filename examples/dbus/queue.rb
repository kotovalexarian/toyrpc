#!/usr/bin/env ruby
# frozen_string_literal: true

require 'bundler/setup'

require 'nio'
require 'toyrpc/dbus'

class QueueHandler
  INTROSPECT = File.read(File.expand_path('queue.xml', __dir__)).freeze

  def initialize
    @queue = []
  end

  def method_call(message)
    case message.interface
    when 'org.freedesktop.DBus.Introspectable'
      case message.member
      when 'Introspect' then introspect message
      end
    when 'com.example.Queue'
      case message.member
      when 'push' then push message
      when 'pop'  then pop  message
      end
    end
  end

private

  def introspect(message)
    ::ToyRPC::DBus::Message.reply_to message, [['s', INTROSPECT]]
  end

  def push(message)
    str = String message.params.first
    @queue << str
    ::ToyRPC::DBus::Message.reply_to message, []
  end

  def pop(message)
    ::ToyRPC::DBus::Message.reply_to message, [['s', @queue.shift || '']]
  end
end

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

dbus_manager = ToyRPC::DBus::Manager.new queue_handler

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

###########
# IO code #
###########

selector = NIO::Selector.new

dbus_manager.gateways.each do |dbus_gateway|
  bus           = dbus_gateway.bus
  message_queue = bus.message_queue

  monitor = selector.register message_queue.socket, :r

  monitor.value = lambda do
    begin
      message_queue.buffer_from_socket_nonblock
    rescue EOFError, SystemCallError
      selector.deregister message_queue.socket
      next
    end

    while (message = message_queue.message_from_buffer_nonblock)
      bus.process message
    end
  end
end

loop do
  selector.select do |monitor|
    monitor.value.call
  end
end
