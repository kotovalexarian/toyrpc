# frozen_string_literal: true

require 'dbus'

module ToyRPC
  module DBus
    class ServicePool
      def initialize
        @service = nil
      end

      def add(service)
        @service = service
      end

      def get_node(path)
        @service.get_node(path)
      end
    end
  end
end
