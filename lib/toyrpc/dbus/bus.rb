# frozen_string_literal: true

module ToyRPC
  module DBus
    class Bus < ::DBus::Connection
      def initialize(address, handler)
        @unique_name = nil
        @proxy       = nil

        @method_call_replies = {}
        @method_call_msgs    = {}
        @signal_matchrules   = {}

        @handler = handler

        @message_queue = MessageQueue.new address
        @object_root   = ::DBus::Node.new '/'

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

      def send_sync_or_async(message)
        ret = nil

        if block_given?
          on_return(message) do |rmsg|
            if rmsg.is_a? ::DBus::Error
              yield rmsg
            else
              yield rmsg, *rmsg.params
            end
          end
          push(message)
        else
          send_sync(message) do |rmsg|
            raise rmsg if rmsg.is_a? ::DBus::Error

            ret = rmsg.params
          end
        end

        ret
      end

      def send_sync(message, &retc)
        return if message.nil?

        push(message)
        @method_call_msgs[message.serial] = message
        @method_call_replies[message.serial] = retc

        retm = pop
        return if retm.nil?

        process(retm)
        while @method_call_replies.key? message.serial
          retm = pop
          process(retm)
        end
      end

      def emit(service, obj, intf, sig, *args)
        m = ::DBus::Message.new ::DBus::Message::SIGNAL
        m.path = obj.path
        m.interface = intf.name
        m.member = sig.name
        m.sender = service.name
        i = 0
        sig.params.each do |par|
          m.add_param(par.type, args[i])
          i += 1
        end
        push(m)
      end

    private

      def push(message)
        @message_queue.socket.write message.marshall
      end

      def pop
        @message_queue.pop
      end

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
        push begin
               @handler.method_call message
             rescue => e
               Message.reply_with_exception message, e
             end
      end

      def process_signal(message)
        @signal_matchrules.dup.each do |mrs, slot|
          slot.call(message) if DBus::MatchRule.new.from_s(mrs).match(message)
        end
      end
    end
  end
end
