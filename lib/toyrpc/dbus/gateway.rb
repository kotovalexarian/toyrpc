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

        @proxies_mutex = Mutex.new
        @proxies = {}
      end

      def bus
        @bus.value
      end

      def proxy(name)
        unless name.instance_of? Symbol
          raise TypeError, "Expected #{Symbol}, got #{name}"
        end

        @proxies[name]&.value or raise "Unknown proxy: #{name.to_s.inspect}"
      end

      def add_proxy(name)
        unless name.instance_of? Symbol
          raise TypeError, "Expected #{Symbol}, got #{name.class}"
        end

        @proxies_mutex.synchronize do
          unless @proxies[name].nil?
            raise "Proxy name already in use: #{name.to_s.inspect}"
          end

          @proxies[name] = Concurrent::ThreadLocalVar.new do
            yield bus
          end
        end

        nil
      end

      def add_proxy_class(name, klass)
        unless klass.instance_of? Class
          raise TypeError, "Expected #{Class}, got #{klass.class}"
        end

        add_proxy name, &klass.method(:new)
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
