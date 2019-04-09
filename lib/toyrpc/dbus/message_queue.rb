# frozen_string_literal: true

module ToyRPC
  module DBus
    class MessageQueue < ::DBus::MessageQueue
      def address_args
        @address_args ||= @address.params.map do |k, v|
          [
            k.to_s.freeze,
            v.gsub(/%(..)/) { |_m| [Regexp.last_match(1)].pack 'H2' }.freeze,
          ]
        end.to_h.freeze
      end

    private

      def connect
        case @address.transport
        when :unix
          connect_to_unix address_args
        when :tcp
          connect_to_tcp address_args
        when :launchd
          connect_to_launchd address_args
        end
      end
    end
  end
end
