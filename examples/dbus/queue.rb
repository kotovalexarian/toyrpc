#!/usr/bin/env ruby
# frozen_string_literal: true

require 'bundler/setup'

require 'nio'
require 'toyrpc/dbus'

class QueueHandler < ToyRPC::DBus::BasicHandler
  INTROSPECT = File.read(File.expand_path('queue.xml', __dir__)).freeze

  def initialize
    @queue = []
  end

  def process_call(bus, message)
    case message.interface
    when 'org.freedesktop.DBus.Introspectable'
      case message.member
      when 'Introspect' then introspect bus, message
      end
    when 'com.example.Queue'
      case message.member
      when 'push' then push bus, message
      when 'pop'  then pop  bus, message
      end
    end
  end

private

  def introspect(bus, message)
    bus.message_queue.write_message(
      begin
        ::ToyRPC::DBus::Message.reply_to message, [['s', INTROSPECT]]
      rescue => e
        ::ToyRPC::DBus::Message.reply_with_exception message, e
      end,
    )
  end

  def push(bus, message)
    bus.message_queue.write_message(
      begin
        str = String message.params.first
        @queue << str
        ::ToyRPC::DBus::Message.reply_to message, []
      rescue => e
        ::ToyRPC::DBus::Message.reply_with_exception message, e
      end,
    )
  end

  def pop(bus, message)
    bus.message_queue.write_message(
      begin
        ::ToyRPC::DBus::Message.reply_to message, [['s', @queue.shift || '']]
      rescue => e
        ::ToyRPC::DBus::Message.reply_with_exception message, e
      end,
    )
  end
end

def request_service(dbus_gateway, service_name)
  bus = dbus_gateway.bus

  message = ToyRPC::DBus::DBusFactory.request_name_message(
    bus.unique_name,
    service_name,
    ToyRPC::DBus::NAME_FLAG_REPLACE_EXISTING,
  )

  bus.send_async message do |return_message, result|
    raise return_message if return_message.is_a? ::DBus::Error
    unless result == ToyRPC::DBus::REQUEST_NAME_REPLY_PRIMARY_OWNER
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

  monitor = selector.register message_queue, :rw

  monitor.value = lambda do
    begin
      message_queue.flush_write_buffer
    rescue IO::WaitWritable
      nil
    end

    begin
      message_queue.flush_read_buffer
    rescue IO::WaitReadable
      return
    end

    while (message = message_queue.read_message)
      bus.process message
    end
  rescue EOFError, SystemCallError
    selector.deregister message_queue
  end
end

loop do
  selector.select do |monitor|
    monitor.value.call
  end
end
