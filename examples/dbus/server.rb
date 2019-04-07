#!/usr/bin/env ruby
# frozen_string_literal: true

require 'dbus'

class DBusInterface
  attr_reader :name, :signals, :methods

  def initialize(name:, signals:, methods:)
    self.name = name
    @signals = signals
    @methods = methods
  end

private

  def name=(value)
    unless value.is_a? Symbol
      raise TypeError, "Expected #{Symbol}, got #{value.class}"
    end

    @name = value
  end
end

class DBusMethod
  attr_reader :name, :ins, :outs

  def initialize(name:, ins:, outs:)
    self.name = name
    @ins = ins
    @outs = outs
  end

  def types
    outs.values
  end

  def to_xml
    "<method name=\"#{name}\">\n" \
    "#{ins_to_xml}"               \
    "#{outs_to_xml}"              \
    "</method>\n"
  end

  def ins_to_xml
    ins.map do |name, type|
      "<arg name=\"#{name}\" direction=\"in\" type=\"#{type}\"/>\n"
    end.join
  end

  def outs_to_xml
    outs.map do |name, type|
      "<arg name=\"#{name}\" direction=\"out\" type=\"#{type}\"/>\n"
    end.join
  end

  def name=(value)
    unless value.is_a? Symbol
      raise TypeError, "Expected #{Symbol}, got #{value.class}"
    end

    @name = value
  end
end

class DBusParam
  DIRECTIONS = %i[in out].freeze
  TYPES = %i[i].freeze

  attr_reader :name, :direction, :type

  def initialize(name:, direction:, type:)
    self.name = name
    self.direction = direction
    self.type = type
  end

  def to_xml
    "<arg name=\"#{name}\" direction=\"#{direction}\" type=\"#{type}\"/>"
  end

  def in?
    direction == :in
  end

  def out?
    direction == :out
  end

private

  def name=(value)
    unless value.is_a? Symbol
      raise TypeError, "Expected #{Symbol}, got #{value.class}"
    end

    @name = value
  end

  def direction=(value)
    raise "Invalid value: #{value.inspect}" unless DIRECTIONS.include? value

    @direction = value
  end

  def type=(value)
    raise "Invalid value: #{value.inspect}" unless TYPES.include? value

    @type = value
  end
end

class DBusObject
  attr_reader :path, :intfs
  attr_writer :service

  def initialize(path, handler, intfs)
    @path = path
    @handler = handler
    @intfs = intfs
    @service = nil
  end

  def dispatch(dbus_message)
    return unless dbus_message.message_type == ::DBus::Message::METHOD_CALL

    @service.bus.message_queue.push(reply(dbus_message))
  end

private

  def reply(dbus_message)
    method_info = get_method_info(dbus_message)
    result = [*@handler.method(method_info.name).call(*dbus_message.params)]
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

    if intfs[dbus_interface_name].nil?
      raise(
        ::DBus.error('org.freedesktop.DBus.Error.UnknownMethod'),
        "Interface \"#{dbus_interface_name}\" " \
        "of object \"#{dbus_object_path}\" doesn't exist",
      )
    end

    if intfs[dbus_interface_name].methods[dbus_method_name].nil?
      raise(
        ::DBus.error('org.freedesktop.DBus.Error.UnknownMethod'),
        "Method \"#{dbus_method_name}\" " \
        "on interface \"#{dbus_interface_name}\" " \
        "of object \"#{dbus_object_path}\" doesn't exist",
      )
    end

    intfs[dbus_interface_name].methods[dbus_method_name]
  end
end

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

INTERFACES = {
  'com.example.MyHandler': DBusInterface.new(
    name:    'com.example.MyHandler',
    signals: {}.freeze,
    methods: {
      add: DBusMethod.new(
        name: :add,
        ins:  { left: 'i', right: 'i' },
        outs: { result: 'i' },
      ).freeze,
      sub: DBusMethod.new(
        name: :sub,
        ins:  { left: 'i', right: 'i' },
        outs: { result: 'i' },
      ).freeze,
      mul: DBusMethod.new(
        name: :mul,
        ins:  { left: 'i', right: 'i' },
        outs: { result: 'i' },
      ).freeze,
    }.freeze,
  ).freeze,
}.freeze

my_handler = MyHandler.new

dbus_socket_name = ARGV[0].to_s.strip

dbus_bus = if dbus_socket_name.empty?
             DBus.session_bus
           else
             DBus::RemoteBus.new dbus_socket_name
           end

dbus_service = dbus_bus.request_service 'com.example.MyHandler'

dbus_object = DBusObject.new '/com/example/MyHandler', my_handler, INTERFACES

dbus_service.export dbus_object

dbus_main = DBus::Main.new
dbus_main << dbus_bus
dbus_main.run
