# frozen_string_literal: true

module ToyRPC
  module DBus
    ##
    # TODO: Delete old callbacks.
    #
    class CallContinuator
      DEFAULT_TIMEOUT = 60.0

      attr_reader :timeout

      def initialize(timeout = DEFAULT_TIMEOUT)
        self.timeout = timeout
        @callbacks = {}
      end

      def register(conn, call_message, &block)
        conn_id = Integer conn.object_id
        serial  = Integer call_message.serial
        key     = "#{conn_id}:#{serial}"

        @callbacks[key] = block
        nil
      end

      def process(conn, return_message)
        reply_serial = return_message.reply_serial
        raise ::DBus::InvalidPacketException if reply_serial.nil?

        conn_id = Integer conn.object_id
        serial  = Integer reply_serial
        key     = "#{conn_id}:#{serial}"

        @callbacks[key]&.call return_message
        @callbacks[key] = nil
      end

    private

      def timeout=(value)
        value = Float value
        raise ArgumentError, "Invalid timeout: #{value}" unless value.positive?

        @timeout = value
      end
    end
  end
end
