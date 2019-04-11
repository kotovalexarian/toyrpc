#!/usr/bin/env ruby
# frozen_string_literal: true

require 'bundler/setup'

require 'nio'
require 'toyrpc/dbus'

class MyHandler < ToyRPC::DBus::BasicHandler
  INTROSPECT = File.read(File.expand_path('server.xml', __dir__)).freeze

  def process_call(bus, message)
    case message.interface
    when 'org.freedesktop.DBus.Introspectable'
      case message.member
      when 'Introspect' then introspect bus, message
      end
    when 'com.example.Greetable'
      case message.member
      when 'greeting' then do_greeting bus, message
      end
    when 'com.example.Calculable'
      case message.member
      when 'add' then do_add bus, message
      when 'sub' then do_sub bus, message
      when 'mul' then do_mul bus, message
      end
    when 'com.example.Helloable'
      case message.member
      when 'hello' then do_hello bus, message
      end
    when 'com.example.Nameable'
      case message.member
      when 'full_name' then do_full_name bus, message
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

  def do_greeting(bus, message)
    bus.message_queue.write_message(
      begin
        ::ToyRPC::DBus::Message.reply_to message, [%w[s Hello!]]
      rescue => e
        ::ToyRPC::DBus::Message.reply_with_exception message, e
      end,
    )
  end

  def do_add(bus, message)
    bus.message_queue.write_message(
      begin
        left, right = message.params
        ::ToyRPC::DBus::Message.reply_to message, [['i', left + right]]
      rescue => e
        ::ToyRPC::DBus::Message.reply_with_exception message, e
      end,
    )
  end

  def do_sub(bus, message)
    bus.message_queue.write_message(
      begin
        left, right = message.params
        ::ToyRPC::DBus::Message.reply_to message, [['i', left - right]]
      rescue => e
        ::ToyRPC::DBus::Message.reply_with_exception message, e
      end,
    )
  end

  def do_mul(bus, message)
    bus.message_queue.write_message(
      begin
        left, right = message.params
        ::ToyRPC::DBus::Message.reply_to message, [['i', left * right]]
      rescue => e
        ::ToyRPC::DBus::Message.reply_with_exception message, e
      end,
    )
  end

  def do_hello(bus, message)
    bus.message_queue.write_message(
      begin
        name = message.params.first
        ::ToyRPC::DBus::Message.reply_to message, [['s', "Hello, #{name}!"]]
      rescue => e
        ::ToyRPC::DBus::Message.reply_with_exception message, e
      end,
    )
  end

  def do_full_name(bus, message)
    bus.message_queue.write_message(
      begin
        first_name, last_name = message.params
        ::ToyRPC::DBus::Message.reply_to message,
                                         [['s', "#{first_name} #{last_name}"]]
      rescue => e
        ::ToyRPC::DBus::Message.reply_with_exception message, e
      end,
    )
  end
end

def request_service(dbus_manager, gateway_name, service_name)
  dbus_manager[gateway_name].proxy(:dbus).request_name(
    service_name,
    ToyRPC::DBus::NAME_FLAG_REPLACE_EXISTING,
  ) do |return_message, r|
    raise return_message if return_message.is_a? ::DBus::Error
    unless r == ToyRPC::DBus::REQUEST_NAME_REPLY_PRIMARY_OWNER
      raise ::DBus::Connection::NameRequestError
    end
  end
end

my_handler = MyHandler.new

dbus_manager = ToyRPC::DBus::Manager.new my_handler

dbus_manager.connect :session
dbus_manager.connect :custom, ARGV[0]

dbus_manager[:session].add_proxy_class :dbus, ToyRPC::DBus::DBusProxy
dbus_manager[:custom].add_proxy_class  :dbus, ToyRPC::DBus::DBusProxy

request_service dbus_manager, :session, 'com.example.MyHandler1'
request_service dbus_manager, :session, 'com.example.MyHandler2'
request_service dbus_manager, :custom,  'com.example.MyHandler3'

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
