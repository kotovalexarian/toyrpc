#!/usr/bin/env ruby
# frozen_string_literal: true

require 'bundler/setup'

require 'nio'
require 'toyrpc/dbus'

class QueueProxy < ToyRPC::DBus::BasicProxy
  def pop
    call_message = ::DBus::Message.new ::DBus::Message::METHOD_CALL
    call_message.sender = bus.unique_name
    call_message.destination = 'com.example.Queue'
    call_message.path = '/com/example/Queue'
    call_message.interface = 'com.example.Queue'
    call_message.member = 'pop'

    bus.send_async call_message do |_return_message, result|
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
    message_queue.buffer_to_socket_nonblock

    message_queue.buffer_from_socket_nonblock

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
