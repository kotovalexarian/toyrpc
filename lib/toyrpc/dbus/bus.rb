# frozen_string_literal: true

module ToyRPC
  module DBus
    class Bus
      attr_reader :unique_name, :message_queue

      def initialize(address, handler)
        @unique_name = nil

        @call_continuator = CallContinuator.new

        @handler = handler

        @message_queue = Connections::Unix.new(
          Address.new(address).to_unix_sockaddr,
          MARSHALLER,
          UNMARSHALLER,
        )

        ::DBus::Client.new(@message_queue.to_io).authenticate

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
        @call_continuator.register @message_queue, message do |return_message|
          if block_given?
            if return_message.is_a? ::DBus::Error
              yield return_message
            else
              yield return_message, *return_message.params
            end
          end
        end

        @message_queue.write_message message
      end

    private

      def dbus_proxy
        @dbus_proxy ||= DBusProxy.new self
      end

      def process_return_or_error(message)
        if message.message_type == ::DBus::Message::ERROR
          @call_continuator.process @message_queue, ::DBus::Error.new(message)
        else
          @call_continuator.process @message_queue, message
        end
      end

      def process_call(message)
        @handler&.process_call self, message
      end

      def process_signal(message)
        @handler&.process_signal self, message
      end
    end
  end
end
