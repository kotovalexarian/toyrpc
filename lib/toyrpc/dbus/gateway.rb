# frozen_string_literal: true

module ToyRPC
  module DBus
    class Gateway
      attr_reader :bus

      def initialize(address, handler)
        self.address = address

        @bus = Bus.new address, handler

        @proxies_mutex = Mutex.new
        @proxies = {}
      end

    private

      def address=(value)
        unless value.instance_of? Address
          raise TypeError, "Expected #{Address}, got #{value.class}"
        end

        @address = value.frozen? ? value : value.freeze
      end
    end
  end
end
