# frozen_string_literal: true

module ToyRPC
  module DBus
    class CallContinuator
      def initialize
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
    end
  end
end
