#!/usr/bin/env ruby
# frozen_string_literal: true

require 'bundler/setup'

require 'nio'
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

    bus.send_async call_message

    nil
  end
end

dbus_manager = ToyRPC::DBus::Manager.new

dbus_manager.connect :session

dbus_manager[:session].add_proxy_class :queue, QueueProxy

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
  dbus_manager[:session].proxy(:queue).push SecureRandom.hex

  selector.select do |monitor|
    monitor.value.call
  end

  sleep 1
end
