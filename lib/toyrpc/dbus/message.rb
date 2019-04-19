# frozen_string_literal: true

module ToyRPC
  module DBus
    class Message
      def self.method_call(sender, # rubocop:disable Metrics/ParameterLists
                           destination, path, interface, member, *args)
        ::DBus::Message.new(::DBus::Message::METHOD_CALL).tap do |m|
          m.reply_serial = nil
          m.sender       = sender
          m.destination  = destination
          m.path         = path
          m.interface    = interface
          m.member       = member
          m.error_name   = nil

          args.each do |a|
            m.add_param a[0], a[1]
          end
        end
      end

      def self.reply_to(call_message, params)
        ::DBus::Message.new(::DBus::Message::METHOD_RETURN).tap do |m|
          m.reply_serial = call_message.serial
          m.sender       = nil
          m.destination  = call_message.sender
          m.path         = nil
          m.interface    = nil
          m.member       = nil
          m.error_name   = nil

          params.each do |type, data|
            m.add_param type.to_s, data
          end
        end
      end

      def self.reply_with_exception(call_message, exception)
        ::DBus::Message.new(::DBus::ERROR).tap do |m|
          m.reply_serial = call_message.serial
          m.sender       = nil
          m.destination  = call_message.sender
          m.path         = nil
          m.interface    = nil
          m.member       = nil

          m.error_name = if exception.is_a? ::DBus::Error
                           exception.name
                         else
                           'org.freedesktop.DBus.Error.Failed'
                         end

          m.add_param ::DBus::Type::STRING, exception.message
          m.add_param ::DBus.type('as'),    exception.backtrace
        end
      end
    end
  end
end
