# frozen_string_literal: true

module ToyRPC
  module DBus
    ##
    # FIXME: bus class is not thread-safe,
    # so memoize into thread-local variable
    #
    class ConnectionPool
      SYSTEM_SOCKET_NAME = 'unix:path=/var/run/dbus/system_bus_socket'

      def self.socket_name(socket_name)
        case socket_name
        when :system
          system_socket_name
        when :session
          session_socket_name
        else
          socket_name
        end
      end

      def self.system_socket_name
        @system_socket_name ||= SYSTEM_SOCKET_NAME.freeze
      end

      def self.session_socket_name
        @session_socket_name ||= ::DBus::SessionBus.session_bus_address.freeze
      end

      def initialize
        @connections = {}
        @mutex = Mutex.new
      end

      def connect(socket_name)
        bus = Bus.new self.class.socket_name socket_name

        @mutex.synchronize do
          unless @connections[bus.daemon_id].nil?
            raise "Already connected to #{bus.daemon_id}"
          end

          @connections[bus.daemon_id] = bus
        end
      end

      def buses
        @connections.values
      end
    end
  end
end
