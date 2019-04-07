# frozen_string_literal: true

module ToyRPC
  module DBus
    class Param
      DIRECTIONS = %i[in out].freeze
      TYPES = %i[y b n q i u x t d s o g a v h].freeze

      attr_reader :name, :direction, :type

      def initialize(name:, direction:, type:)
        self.name = name
        self.direction = direction
        self.type = type
      end

      def to_xml
        "<arg name=\"#{name}\" direction=\"#{direction}\" type=\"#{type}\"/>"
      end

      def in?
        direction == :in
      end

      def out?
        direction == :out
      end

    private

      def name=(value)
        unless value.is_a? Symbol
          raise TypeError, "Expected #{Symbol}, got #{value.class}"
        end

        @name = value
      end

      def direction=(value)
        raise "Invalid value: #{value.inspect}" unless DIRECTIONS.include? value

        @direction = value
      end

      def type=(value)
        raise "Invalid value: #{value.inspect}" unless TYPES.include? value

        @type = value
      end
    end
  end
end
