# frozen_string_literal: true

module ToyRPC
  module DBus
    class UnixConnection
      MSG_BUF_SIZE = 4096

      attr_reader :address, :socket

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

      def push(message)
        socket.write message.marshall
      end

      def pop
        buffer_from_socket_nonblock
        message = message_from_buffer_nonblock
        while message.nil?
          r, _d, _d = IO.select [socket]
          next unless r && r[0] == socket

          buffer_from_socket_nonblock
          message = message_from_buffer_nonblock
        end
        message
      end

    private

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

        socket.fcntl(Fcntl::F_SETFD, Fcntl::FD_CLOEXEC)

        sockaddr = if !address_args[:abstract].nil?
                     if ::DBus::HOST_END == ::DBus::LIL_END
                       "\1\0\0#{address_args[:abstract]}"
                     else
                       "\0\1\0#{address_args[:abstract]}"
                     end
                   elsif !address_args[:path].nil?
                     Socket.pack_sockaddr_un(address_args[:path])
                   end

        socket.connect(sockaddr)

        ::DBus::Client.new(socket).authenticate
      end

    public # FIXME: fix event loop instead

      def message_from_buffer_nonblock
        return nil if @buffer.empty?

        begin
          ret, size = ::DBus::Message.new.unmarshall_buffer(@buffer)
          @buffer.slice!(0, size)
          ret
        rescue ::DBus::IncompleteBufferException
          nil
        end
      end

      def buffer_from_socket_nonblock
        @buffer += @socket.read_nonblock(MSG_BUF_SIZE)
      rescue EOFError
        raise
      rescue Errno::EAGAIN
        nil
      rescue Exception
        @buffer += @socket.recv(MSG_BUF_SIZE)
      end
    end
  end
end
