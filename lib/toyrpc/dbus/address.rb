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

      def unix?
        transport == :unix
      end

      def launchd?
        transport == :launchd
      end

      def tcp?
        transport == :tcp
      end

      def nonce_tcp?
        transport == :nonce_tcp
      end

      def unixexec?
        transport == :unixexec
      end

      def autolaunch?
        transport == :autolaunch
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
    end
  end
end
