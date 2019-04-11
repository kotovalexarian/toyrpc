#!/usr/bin/env ruby
# frozen_string_literal: true

require 'bundler/setup'

require 'nio'
require 'toyrpc/dbus'

module Factory
  def pop_message(sender)
    ::DBus::Message.new(::DBus::Message::METHOD_CALL).tap do |m|
      m.sender      = sender
      m.destination = 'com.example.Queue'
      m.path        = '/com/example/Queue'
      m.interface   = 'com.example.Queue'
      m.member      = 'pop'
    end
  end
end

class QueueProxy < ToyRPC::DBus::BasicProxy
  include Factory

  def pop
    message = pop_message bus.unique_name

    bus.send_async message do |_return_message, result|
      yield String(Array(result).first)
    end
  end
end

dbus_manager = ToyRPC::DBus::Manager.new

dbus_manager.connect :custom, ARGV[0]

dbus_manager[:custom].add_proxy_class :queue, QueueProxy

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
  dbus_manager[:custom].proxy(:queue).pop do |value|
    unless value.empty?
      puts value
      sleep 0.1
      next
    end
  end

  selector.select do |monitor|
    monitor.value.call
  end

  sleep 1
end
