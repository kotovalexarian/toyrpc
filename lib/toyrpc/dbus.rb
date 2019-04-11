# frozen_string_literal: true

require 'toyrpc'

require 'toyrpc/dbus/address'
require 'toyrpc/dbus/basic_handler'
require 'toyrpc/dbus/bus'
require 'toyrpc/dbus/call_continuator'
require 'toyrpc/dbus/dbus_factory'
require 'toyrpc/dbus/manager'
require 'toyrpc/dbus/message'

require 'dbus'

module ToyRPC
  module DBus
    SYSTEM_SOCKET_NAME = 'unix:path=/var/run/dbus/system_bus_socket'

    NAME_FLAG_ALLOW_REPLACEMENT = 0x1
    NAME_FLAG_REPLACE_EXISTING  = 0x2
    NAME_FLAG_DO_NOT_QUEUE      = 0x4

    REQUEST_NAME_REPLY_PRIMARY_OWNER = 0x1
    REQUEST_NAME_REPLY_IN_QUEUE      = 0x2
    REQUEST_NAME_REPLY_EXISTS        = 0x3
    REQUEST_NAME_REPLY_ALREADY_OWNER = 0x4

    MARSHALLER = lambda do |message|
      message.marshall
    end

    UNMARSHALLER = lambda do |buffer|
      ::DBus::Message.new.unmarshall_buffer buffer
    rescue ::DBus::IncompleteBufferException
      [nil, 0]
    end

    def self.default_socket_name(bus_name)
      case bus_name
      when :system
        system_socket_name
      when :session
        session_socket_name
      else
        raise "Not a well-known bus name: #{bus_name.inspect}"
      end
    end

    def self.system_socket_name
      @system_socket_name ||= SYSTEM_SOCKET_NAME.freeze
    end

    def self.session_socket_name
      @session_socket_name ||= ::DBus::SessionBus.session_bus_address.freeze
    end
  end
end
