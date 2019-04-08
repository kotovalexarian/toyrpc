# frozen_string_literal: true

module ToyRPC
  module DBus
    class Bus < ::DBus::Connection
      def initialize(socket_name)
        super
        send_hello
      end

      def daemon_id
        @daemon_id ||= dbus_proxy.getid
      end

      def add_service(name)
        service_pool.add ::DBus::Service.new name, self
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

      def service_pool
        @service_pool ||= ServicePool.new
      end

      def dbus_proxy
        @dbus_proxy ||= DBusProxy.new self
      end

      def send_hello
        @unique_name = dbus_proxy.hello
        ::DBus.logger.debug "Got hello reply. Our unique_name is #{unique_name}"
        service_pool.add ::DBus::Service.new unique_name, self
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
        obj = service_pool.get_node(message.path)&.object
        return if obj.nil? # FIXME: pushes no reply

        obj.dispatch(message)
      end

      def process_signal(message)
        @signal_matchrules.dup.each do |mrs, slot|
          slot.call(message) if DBus::MatchRule.new.from_s(mrs).match(message)
        end
      end
    end
  end
end
