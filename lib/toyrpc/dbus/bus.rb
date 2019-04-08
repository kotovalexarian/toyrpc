# frozen_string_literal: true

module ToyRPC
  module DBus
    class Bus < ::DBus::Connection
      def initialize(socket_name, object)
        super(socket_name)
        @object = object
        @object&.bus = self
        send_hello
      end

      def daemon_id
        @daemon_id ||= dbus_proxy.getid
      end

      def process(message)
        return if message.nil?

        case message.message_type
        when ::DBus::Message::ERROR, ::DBus::Message::METHOD_RETURN
          process_return_or_error message
        when ::DBus::Message::METHOD_CALL
          process_call message
        when ::DBus::Message::SIGNAL
          process_signal message
        end
      rescue Exception => e # rubocop:disable Lint/RescueException
        raise message.annotate_exception(e)
      end

    private

      def dbus_proxy
        @dbus_proxy ||= DBusProxy.new self
      end

      def send_hello
        @unique_name = dbus_proxy.hello
      end

      def process_return_or_error(message)
        raise ::DBus::InvalidPacketException if message.reply_serial.nil?

        mcs = @method_call_replies[message.reply_serial]
        return if mcs.nil?

        if message.message_type == ::DBus::Message::ERROR
          mcs.call(::DBus::Error.new(message))
        else
          mcs.call(message)
        end

        @method_call_replies.delete(message.reply_serial)
        @method_call_msgs.delete(message.reply_serial)
      end

      def process_call(message)
        @object.dispatch(message)
      end

      def process_signal(message)
        @signal_matchrules.dup.each do |mrs, slot|
          slot.call(message) if DBus::MatchRule.new.from_s(mrs).match(message)
        end
      end
    end
  end
end
