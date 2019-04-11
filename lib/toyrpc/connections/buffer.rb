# frozen_string_literal: true

module ToyRPC
  module Connections
    class Buffer
      def initialize(capacity)
        @capacity = Integer capacity
        unless @capacity.positive?
          raise ArgumentError, "Invalid capacity: #@capacity"
        end

        clear
      end

      def remaining
        @capacity - @to
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

        unless count.positive?
          raise ArgumentError, 'Expected count to be positive'
        end

        if count > @to - @from
          raise BufferOverflowError, 'Not enough data in buffer'
        end

        @from += count
        nil
      end

      def put(str)
        str = String str
        length = str.length

        if length > @capacity - @to
          raise BufferOverflowError, 'Not enough space in buffer'
        end

        @buffer[@to...(@to + length)] = str
        @to += length
        nil
      end
    end
  end
end
