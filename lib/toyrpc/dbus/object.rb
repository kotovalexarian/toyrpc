# frozen_string_literal: true

module ToyRPC
  module DBus
    class Object
      def initialize(handler)
        @handler = handler
      end

      def reply(dbus_message)
        @handler.method_call(dbus_message)
      rescue => e
        Message.reply_with_exception(dbus_message, e)
      end
    end
  end
end
