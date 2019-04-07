# frozen_string_literal: true

module ToyRPC
  module DBus
    class Manager
      SYSTEM_SOCKET_NAME = 'unix:path=/var/run/dbus/system_bus_socket'

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

      def initialize
        @mutex = Mutex.new
        @by_bus_name = {}
        @by_id = {}
      end

      def buses
        @by_bus_name.values
      end

      def [](bus_name)
        @by_bus_name[bus_name] or raise "Unknown bus name: #{bus_name}"
      end

      def connect(bus_name,
                  socket_name = self.class.default_socket_name(bus_name))
        @mutex.synchronize do
          unless @by_bus_name[bus_name].nil?
            raise "Bus name already in use: #{bus_name.inspect}"
          end

          bus = Bus.new socket_name

          unless @by_id[bus.daemon_id].nil?
            raise "Already connected to bus #{bus_name.inspect} " \
                  "(#{bus.daemon_id})"
          end

          @by_bus_name[bus_name] = bus
          @by_id[bus.daemon_id] = bus
        end
      end
    end
  end
end
