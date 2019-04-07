# frozen_string_literal: true

module ToyRPC
  module DBus
    class Method
      attr_reader :name, :to, :ins, :outs

      def initialize(name:, to:, ins:, outs:)
        self.name = name
        self.to = to
        self.ins = ins
        self.outs = outs
      end

      def to_xml
        "<method name=\"#{name}\">"  \
        "#{ins.map(&:to_xml).join}"  \
        "#{outs.map(&:to_xml).join}" \
        '</method>'
      end

    private

      def name=(value)
        unless value.is_a? Symbol
          raise TypeError, "Expected #{Symbol}, got #{value.class}"
        end

        @name = value
      end

      def to=(value)
        unless value.is_a? Symbol
          raise TypeError, "Expected #{Symbol}, got #{value.class}"
        end

        @to = value
      end

      def ins=(value)
        @ins = Array(
          value.map do |item|
            unless item.instance_of? Param
              raise TypeError, "Expected #{Param}, got #{item.class}"
            end
            raise 'Expected input param' unless item.in?

            item
          end,
        ).freeze
      end

      def outs=(value)
        @outs = Array(
          value.map do |item|
            unless item.instance_of? Param
              raise TypeError, "Expected #{Param}, got #{item.class}"
            end
            raise 'Expected output param' unless item.out?

            item
          end,
        ).freeze
      end
    end
  end
end
