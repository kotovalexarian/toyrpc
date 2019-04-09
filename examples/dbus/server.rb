#!/usr/bin/env ruby
# frozen_string_literal: true

require 'bundler/setup'

require 'toyrpc/dbus'

class MyHandler
  INTROSPECT = File.read(File.expand_path('server.xml', __dir__)).freeze

  def method_call(message)
    case message.interface
    when 'org.freedesktop.DBus.Introspectable'
      case message.member
      when 'Introspect' then introspect message
      end
    when 'com.example.Greetable'
      case message.member
      when 'greeting' then do_greeting message
      end
    when 'com.example.Calculable'
      case message.member
      when 'add' then do_add message
      when 'sub' then do_sub message
      when 'mul' then do_mul message
      end
    when 'com.example.Helloable'
      case message.member
      when 'hello' then do_hello message
      end
    when 'com.example.Nameable'
      case message.member
      when 'full_name' then do_full_name message
      end
    end
  end

private

  def introspect(message)
    ::ToyRPC::DBus::Message.reply_to message, [['s', INTROSPECT]]
  end

  def do_greeting(message)
    ::ToyRPC::DBus::Message.reply_to message, [%w[s Hello!]]
  end

  def do_add(message)
    left, right = message.params
    ::ToyRPC::DBus::Message.reply_to message, [['i', left + right]]
  end

  def do_sub(message)
    left, right = message.params
    ::ToyRPC::DBus::Message.reply_to message, [['i', left - right]]
  end

  def do_mul(message)
    left, right = message.params
    ::ToyRPC::DBus::Message.reply_to message, [['i', left * right]]
  end

  def do_hello(message)
    name = message.params.first
    ::ToyRPC::DBus::Message.reply_to message, [['s', "Hello, #{name}!"]]
  end

  def do_full_name(message)
    first_name, last_name = message.params
    ::ToyRPC::DBus::Message.reply_to message,
                                     [['s', "#{first_name} #{last_name}"]]
  end
end

def request_service(dbus_manager, gateway_name, service_name)
  dbus_manager[gateway_name].proxy(:dbus).request_name(
    service_name,
    ::DBus::Connection::NAME_FLAG_REPLACE_EXISTING,
  ) do |return_message, r|
    raise return_message if return_message.is_a? ::DBus::Error
    unless r == ::DBus::Connection::REQUEST_NAME_REPLY_PRIMARY_OWNER
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

dbus_main = DBus::Main.new

dbus_manager.gateways.each do |dbus_gateway|
  dbus_main << dbus_gateway.bus
end

dbus_main.run
