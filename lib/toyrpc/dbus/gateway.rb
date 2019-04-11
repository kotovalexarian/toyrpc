# frozen_string_literal: true

module ToyRPC
  module DBus
    class Gateway
      attr_reader :bus

      def initialize(address, handler)
        @bus = Bus.new address, handler
      end
    end
  end
end
