# frozen_string_literal: true

require 'dbus'

require 'toyrpc/dbus/bus'
require 'toyrpc/dbus/interface'
require 'toyrpc/dbus/method'
require 'toyrpc/dbus/object'
require 'toyrpc/dbus/param'
require 'toyrpc/dbus/service_pool'

module ToyRPC
  module DBus
    SYSTEM_SOCKET_NAME = 'unix:path=/var/run/dbus/system_bus_socket'

    def self.system_socket_name
      SYSTEM_SOCKET_NAME
    end

    def self.session_socket_name
      ::DBus::SessionBus.session_bus_address
    end

    def self.bus(socket_name)
      Bus.new(socket_name)
    end
  end
end
