# frozen_string_literal: true

module ToyRPC
  module DBus
    class Gateway
      def initialize(daemon_id, socket_name)
        self.daemon_id = daemon_id
        self.socket_name = socket_name

        @bus = Concurrent::ThreadLocalVar.new do
          Bus.new(socket_name).tap do |bus|
            raise 'IDs do not match' if bus.daemon_id != daemon_id
          end
        end
      end

      def bus
        @bus.value
      end

    private

      def daemon_id=(value)
        unless value.instance_of? String
          raise TypeError, "Expected #{String}, got #{value.class}"
        end

        @daemon_id = value.frozen? ? value : value.freeze
      end

      def socket_name=(value)
        unless value.instance_of? String
          raise TypeError, "Expected #{String}, got #{value.class}"
        end

        @socket_name = value.frozen? ? value : value.freeze
      end
    end
  end
end
