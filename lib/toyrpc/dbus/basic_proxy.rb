# frozen_string_literal: true

module ToyRPC
  module DBus
    class BasicProxy
      def initialize(bus)
        self.bus = bus
      end

    private

      attr_reader :bus

      def bus=(value)
        unless value.instance_of? Bus
          raise TypeError, "Expected #{Bus}, got #{value.class}"
        end

        @bus = value
      end
    end
  end
end
