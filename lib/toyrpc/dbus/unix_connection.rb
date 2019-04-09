# frozen_string_literal: true

module ToyRPC
  module DBus
    class UnixConnection < ::DBus::MessageQueue
      undef_method :push
      undef_method :pop
      undef_method :connect
      undef_method :init_connection
      undef_method :connect_to_tcp
      undef_method :connect_to_unix
      undef_method :connect_to_launchd

      attr_reader :address

      # FIXME: do not expose internals
      attr_reader :socket

      def initialize(address)
        self.address = address
        @buffer = ''
        connect
      end

      def address_args
        @address_args ||= address.params.map do |k, v|
          [
            k,
            v.gsub(/%(..)/) { |_m| [Regexp.last_match(1)].pack 'H2' }.freeze,
          ]
        end.to_h.freeze
      end

    private

      # attr_reader :socket

      def address=(value)
        value = Address.new value

        unless value.unix?
          raise "Expected \"unix:\" transport, got \"#{value.transport}:\""
        end

        @address = value
      end

      def connect
        @socket = Socket.new(
          Socket::Constants::PF_UNIX,
          Socket::Constants::SOCK_STREAM,
          0,
        )

        @socket.fcntl(Fcntl::F_SETFD, Fcntl::FD_CLOEXEC)

        sockaddr = if !address_args[:abstract].nil?
                     if ::DBus::HOST_END == ::DBus::LIL_END
                       "\1\0\0#{address_args[:abstract]}"
                     else
                       "\0\1\0#{address_args[:abstract]}"
                     end
                   elsif !address_args[:path].nil?
                     Socket.pack_sockaddr_un(address_args[:path])
                   end

        @socket.connect(sockaddr)

        ::DBus::Client.new(@socket).authenticate
      end
    end
  end
end
