# frozen_string_literal: true

module ToyRPC
  module DBus
    class Buffer
      class OverflowError < StandardError; end

      def initialize(capacity)
        @capacity = Integer capacity
        unless @capacity.positive?
          raise ArgumentError, "Invalid capacity: #@capacity"
        end

        clear
      end

      def empty?
        (@to - @from).zero?
      end

      def show
        @buffer[@from...@to]
      end

      def clear
        @buffer = ("\0" * @capacity).force_encoding(Encoding::BINARY)
        @from = 0
        @to = 0
        nil
      end

      def shift(count)
        count = Integer count
        raise OverflowError, 'Not enough data in buffer' if count > @to - @from

        @from += count
        nil
      end

      def put(str)
        str = String str
        length = str.length

        if length > @capacity - @to
          raise OverflowError, 'Not enough space in buffer'
        end

        @buffer[@to...(@to + length)] = str
        @to += length
        nil
      end
    end
  end
end
