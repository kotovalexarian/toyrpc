# frozen_string_literal: true

module ToyRPC
  module DBus
    class Interface
      attr_reader :name, :signals, :methods

      def initialize(name:, signals:, methods:)
        self.name = name
        @signals = signals
        @methods = methods
      end

    private

      def name=(value)
        unless value.is_a? Symbol
          raise TypeError, "Expected #{Symbol}, got #{value.class}"
        end

        @name = value
      end
    end
  end
end
