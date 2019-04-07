#!/usr/bin/env ruby
# frozen_string_literal: true

require 'dbus'
require 'ostruct'

class MyHandler
  def add(left, right)
    left + right
  end

  def sub(left, right)
    left - right
  end

  def mul(left, right)
    left * right
  end
end

my_handler = MyHandler.new

class MyHandlerDBusObject
  attr_reader :path
  attr_writer :service

  def initialize(path, my_handler)
    @path = path
    @my_handler = my_handler
    @service = nil
  end

  def dispatch(dbus_message)
    return unless dbus_message.message_type == ::DBus::Message::METHOD_CALL

    @service.bus.message_queue.push(reply(dbus_message))
  end

  def intfs
    INTERFACES
  end

private

  class Interface
    attr_reader :name, :signals, :methods

    def initialize(name:, signals:, methods:)
      @name = name
      @signals = signals
      @methods = methods
    end
  end

  INTERFACES = {
    'com.example.MyHandler': Interface.new(
      name:    'com.example.MyHandler',
      signals: {}.freeze,
      methods: {
        add: OpenStruct.new(
          name:   :add,
          types:  %w[i],
          to_xml: <<~XML,
            <method name="add">
            <arg name="left" direction="in" type="i"/>
            <arg name="left" direction="in" type="i"/>
            <arg name="result" direction="out" type="i"/>
            </method>
          XML
        ).freeze,
        sub: OpenStruct.new(
          name:   :sub,
          types:  %w[i],
          to_xml: <<~XML,
            <method name="sub">
            <arg name="left" direction="in" type="i"/>
            <arg name="left" direction="in" type="i"/>
            <arg name="result" direction="out" type="i"/>
            </method>
          XML
        ).freeze,
        mul: OpenStruct.new(
          name:   :mul,
          types:  %w[i],
          to_xml: <<~XML,
            <method name="mul">
            <arg name="left" direction="in" type="i"/>
            <arg name="left" direction="in" type="i"/>
            <arg name="result" direction="out" type="i"/>
            </method>
          XML
        ).freeze,
      }.freeze,
    ).freeze,
  }.freeze

  def reply(dbus_message)
    method_info = get_method_info(dbus_message)
    result = [*method(method_info.name).call(*dbus_message.params)]
    reply = ::DBus::Message.method_return(dbus_message)
    method_info.types.zip(result).each do |type, data|
      reply.add_param(type, data)
    end
    reply
  rescue StandardError => e
    ::DBus::ErrorMessage.from_exception(dbus_message.annotate_exception(e))
                        .reply_to(dbus_message)
  end

  def get_method_info(dbus_message)
    dbus_object_path    = dbus_message.path.to_s
    dbus_interface_name = dbus_message.interface.to_sym
    dbus_method_name    = dbus_message.member.to_sym

    if INTERFACES[dbus_interface_name].nil?
      raise(
        ::DBus.error('org.freedesktop.DBus.Error.UnknownMethod'),
        "Interface \"#{dbus_interface_name}\" " \
        "of object \"#{dbus_object_path}\" doesn't exist",
      )
    end

    if INTERFACES[dbus_interface_name].methods[dbus_method_name].nil?
      raise(
        ::DBus.error('org.freedesktop.DBus.Error.UnknownMethod'),
        "Method \"#{dbus_method_name}\" " \
        "on interface \"#{dbus_interface_name}\" " \
        "of object \"#{dbus_object_path}\" doesn't exist",
      )
    end

    INTERFACES[dbus_interface_name].methods[dbus_method_name]
  end

  def add(left, right)
    @my_handler.add(left, right)
  end

  def sub(left, right)
    @my_handler.sub(left, right)
  end

  def mul(left, right)
    @my_handler.mul(left, right)
  end
end

dbus_socket_name = ARGV[0].to_s.strip

dbus_bus = if dbus_socket_name.empty?
             DBus.session_bus
           else
             DBus::RemoteBus.new dbus_socket_name
           end

dbus_service = dbus_bus.request_service 'com.example.MyHandler'

dbus_object = MyHandlerDBusObject.new '/com/example/MyHandler', my_handler

dbus_service.export dbus_object

dbus_main = DBus::Main.new
dbus_main << dbus_bus
dbus_main.run
