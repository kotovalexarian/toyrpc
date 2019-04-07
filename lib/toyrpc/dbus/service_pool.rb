# frozen_string_literal: true

module ToyRPC
  module DBus
    class ServicePool
      def initialize
        @services = []
      end

      def add(service)
        @services << service
        service
      end

      def get_node(path)
        @services.each do |service|
          node = service.get_node(path)
          return node if node
        end

        raise "Unknown path: #{path.inspect}"
      end
    end
  end
end
