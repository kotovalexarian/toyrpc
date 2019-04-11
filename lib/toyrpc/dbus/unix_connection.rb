# frozen_string_literal: true

module ToyRPC
  module DBus
    class UnixConnection
      DEFAULT_READ_BUFFER_CAP  = 1024 * 4
      DEFAULT_WRITE_BUFFER_CAP = 1024 * 4

      attr_reader :address, :read_buffer_cap, :write_buffer_cap

      def initialize(address,
                     read_buffer_cap:  DEFAULT_READ_BUFFER_CAP,
                     write_buffer_cap: DEFAULT_WRITE_BUFFER_CAP)
        self.address = address

        self.read_buffer_cap  = read_buffer_cap
        self.write_buffer_cap = write_buffer_cap

        @socket = Socket.new Socket::PF_UNIX, Socket::SOCK_STREAM
        @socket.fcntl Fcntl::F_SETFD, Fcntl::FD_CLOEXEC
        @socket.connect sockaddr

        ::DBus::Client.new(@socket).authenticate
      end

      def to_io
        @socket
      end

      def write_message(message)
        write_buffer.put message.marshall
      end

      def read_message
        return if read_buffer.empty?

        ret, size = ::DBus::Message.new.unmarshall_buffer read_buffer.show
        read_buffer.shift size
        ret
      rescue ::DBus::IncompleteBufferException
        nil
      end

      # @!method flush_read_buffer
      # Read received data from socket to buffer.
      #
      # @raise [IO::WaitReadable] no data is received, just wait
      # @raise [SystemCallError] something went wrong, should not be ignored
      #
      # @example
      #   begin
      #     result = conn.flush_read_buffer
      #   rescue IO::WaitReadable
      #     IO.select [conn]
      #     retry
      #   end
      #
      def flush_read_buffer
        read_buffer.clear
        read_buffer.put @socket.read_nonblock read_buffer.remaining
        nil
      end

      # @!method flush_write_buffer
      # Write buffered data to socket.
      #
      # @raise [IO::WaitWritable] socket is not ready, just wait
      # @raise [SystemCallError] something went wrong, should not be ignored
      #
      # @example
      #   begin
      #     conn.flush_write_buffer
      #   rescue IO::WaitWritable
      #     IO.select nil, [conn]
      #     retry
      #   end
      #
      def flush_write_buffer
        @socket.write_nonblock write_buffer.show
        write_buffer.clear
        nil
      end

    private

      def address=(value)
        value = Address.new value

        unless value.transport == :unix
          raise "Expected \"unix:\" transport, got \"#{value.transport}:\""
        end

        @address = value
      end

      def read_buffer_cap=(value)
        value = Integer value
        raise ArgumentError, "Invalid capacity: #{value}" unless value.positive?

        @read_buffer_cap = value
      end

      def write_buffer_cap=(value)
        value = Integer value
        raise ArgumentError, "Invalid capacity: #{value}" unless value.positive?

        @write_buffer_cap = value
      end

      def read_buffer
        @read_buffer ||= Buffer.new read_buffer_cap
      end

      def write_buffer
        @write_buffer ||= Buffer.new write_buffer_cap
      end

      def address_args
        @address_args ||= address.params.map do |k, v|
          [
            k,
            v.gsub(/%(..)/) { |_m| [Regexp.last_match(1)].pack 'H2' }.freeze,
          ]
        end.to_h.freeze
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
