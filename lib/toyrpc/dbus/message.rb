# frozen_string_literal: true

module ToyRPC
  module DBus
    class Message
      def self.reply_to(call_message, params)
        return_message = ::DBus::Message.method_return(call_message)
        params.each do |type, data|
          return_message.add_param(type.to_s, data)
        end
        return_message
      end

      def self.reply_with_exception(call_message, exception)
        ::DBus::ErrorMessage
          .from_exception(call_message.annotate_exception(exception))
          .reply_to(call_message)
      end
    end
  end
end
