# frozen_string_literal: true

module ToyRPC
  module DBus
    class UnixConnection
      MSG_BUF_SIZE = 4096

      attr_reader :address

      def initialize(address)
        self.address = address
        @read_buffer = ''
        @write_buffer = ''

        @socket = Socket.new Socket::PF_UNIX, Socket::SOCK_STREAM
        @socket.fcntl Fcntl::F_SETFD, Fcntl::FD_CLOEXEC
        @socket.connect sockaddr

        ::DBus::Client.new(@socket).authenticate
      end

      def to_io
        @socket
      end

      def address_args
        @address_args ||= address.params.map do |k, v|
          [
            k,
            v.gsub(/%(..)/) { |_m| [Regexp.last_match(1)].pack 'H2' }.freeze,
          ]
        end.to_h.freeze
      end

      def write_message(message)
        @write_buffer += message.marshall
      end

      def read_message
        return nil if @read_buffer.empty?

        begin
          ret, size = ::DBus::Message.new.unmarshall_buffer(@read_buffer)
          @read_buffer.slice!(0, size)
          ret
        rescue ::DBus::IncompleteBufferException
          nil
        end
      end

      def flush_read_buffer
        @read_buffer += @socket.read_nonblock(MSG_BUF_SIZE)
      end

      def flush_write_buffer
        @socket.write_nonblock @write_buffer
        @write_buffer = ''
      end

    private

      def address=(value)
        value = Address.new value

        unless value.transport == :unix
          raise "Expected \"unix:\" transport, got \"#{value.transport}:\""
        end

        @address = value
      end

      def sockaddr
        if address_args[:abstract]
          if ::DBus::HOST_END == ::DBus::LIL_END
            "\1\0\0#{address_args[:abstract]}"
          else
            "\0\1\0#{address_args[:abstract]}"
          end
        elsif address_args[:path]
          Socket.pack_sockaddr_un(address_args[:path])
        else
          raise "Invalid address: #{address}"
        end
      end
    end
  end
end
