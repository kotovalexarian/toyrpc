# frozen_string_literal: true

module ToyRPC
  module DBus
    class Manager
      def initialize(handler = nil)
        @handler = handler
        @by_bus_name = {}
      end

      def buses
        @by_bus_name.values
      end

      def [](bus_name)
        @by_bus_name[bus_name] or raise "Unknown bus name: #{bus_name}"
      end

      def connect(bus_name, socket_name = DBus.default_socket_name(bus_name))
        address = Address.new socket_name

        unless @by_bus_name[bus_name].nil?
          raise "Bus name already in use: #{bus_name.inspect}"
        end

        @by_bus_name[bus_name] = Bus.new address, @handler

        nil
      end
    end
  end
end
