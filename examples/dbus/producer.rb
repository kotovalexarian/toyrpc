#!/usr/bin/env ruby
# frozen_string_literal: true

require 'bundler/setup'

require 'nio'
require 'securerandom'
require 'toyrpc/dbus'

module Factory
module_function # rubocop:disable Layout/IndentationWidth

  def push_message(sender, str)
    ::DBus::Message.new(::DBus::Message::METHOD_CALL).tap do |m|
      m.sender      = sender
      m.destination = 'com.example.Queue'
      m.path        = '/com/example/Queue'
      m.interface   = 'com.example.Queue'
      m.member      = 'push'

      m.add_param 's', String(str)
    end
  end
end

dbus_manager = ToyRPC::DBus::Manager.new

dbus_manager.connect :session

###########
# IO code #
###########

selector = NIO::Selector.new

dbus_manager.buses.each do |bus|
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
  bus = dbus_manager[:session]

  message = Factory.push_message bus.unique_name, SecureRandom.hex

  bus.send_async message

  selector.select do |monitor|
    monitor.value.call
  end

  sleep 1
end
