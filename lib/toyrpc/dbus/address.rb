# frozen_string_literal: true

module ToyRPC
  module DBus
    class Address
      PARAM_RE = /
        (abstract|argv\d+|bind|dir|env|family|host|guid|
          noncefile|path|port|runtime|scope|tmpdir)
        =
        ([^,]+)
      /x.freeze

      RE = /\A
        (?<transport>unix|launchd|tcp|nonce-tcp|unixexec|autolaunch):
        (?<params>#{PARAM_RE}(,#{PARAM_RE})*)
      \z/x.freeze

      attr_reader :value

      alias to_s value

      def initialize(value)
        self.value = value.to_s
        raise "Invalid address: #{value.inspect}" if match.nil?
      end

      def inspect
        @inspect ||= "#<#{self.class}: #{value}>"
      end

      def transport
        @transport ||= match[:transport].tr('-', '_').to_sym
      end

      def params
        @params ||= match[:params].scan(PARAM_RE).map do |k, v|
          [k.to_sym, v.freeze]
        end.to_h.freeze
      end

      def to_unix_sockaddr
        unless transport == :unix
          raise "Expected \"unix:\" transport, got \"#{transport}:\""
        end

        if unix_args[:abstract]
          if ::DBus::HOST_END == ::DBus::LIL_END
            "\1\0\0#{unix_args[:abstract]}"
          else
            "\0\1\0#{unix_args[:abstract]}"
          end
        elsif unix_args[:path]
          Socket.pack_sockaddr_un unix_args[:path]
        else
          raise "Invalid address: #{value}"
        end
      end

    private

      def value=(value)
        unless value.is_a? String
          raise TypeError, "Expected #{String}, got #{value.class}"
        end

        @value = value.frozen? ? value : value.freeze
      end

      def match
        @match ||= RE.match value
      end

      def unix_args
        @unix_args ||= params.map do |k, v|
          [
            k,
            v.gsub(/%(..)/) { |_m| [Regexp.last_match(1)].pack 'H2' }.freeze,
          ]
        end.to_h.freeze
      end
    end
  end
end
