# frozen_string_literal: true

module ToyRPC
  module DBus
    class Bus < ::DBus::Connection
      undef_method :unique_name
      undef_method :message_queue
      undef_method :initialize
      undef_method :dispatch_message_queue
      undef_method :glibize
      undef_method :send_sync_or_async
      undef_method :introspect_data
      undef_method :introspect
      undef_method :request_service
      undef_method :proxy
      undef_method :wait_for_message
      undef_method :send_sync
      # undef_method :on_return
      undef_method :add_match
      undef_method :remove_match
      undef_method :process
      undef_method :service
      undef_method :emit
      undef_method :send_hello

      attr_reader :unique_name, :message_queue

      def initialize(address, handler)
        @unique_name = nil

        @method_call_replies = {}
        @method_call_msgs    = {}

        @handler = handler

        @message_queue = UnixConnection.new address

        dbus_proxy.hello do |return_message|
          @unique_name = String(return_message.destination)
        end
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

      def send_async(message)
        on_return message do |return_message|
          if block_given?
            if return_message.is_a? ::DBus::Error
              yield return_message
            else
              yield return_message, *return_message.params
            end
          end
        end

        @message_queue.push message
      end

    private

      def dbus_proxy
        @dbus_proxy ||= DBusProxy.new self
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
        @message_queue.push begin
                              @handler.method_call message
                            rescue => e
                              Message.reply_with_exception message, e
                            end
      end

      def process_signal(message)
        @handler&.on_signal message
      end
    end
  end
end
