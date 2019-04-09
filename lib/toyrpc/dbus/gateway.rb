# frozen_string_literal: true

module ToyRPC
  module DBus
    class Gateway
      def initialize(address, handler)
        self.address = address

        @bus = Concurrent::ThreadLocalVar.new do
          Bus.new address, handler
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

      def address=(value)
        unless value.instance_of? Address
          raise TypeError, "Expected #{Address}, got #{value.class}"
        end

        @address = value.frozen? ? value : value.freeze
      end
    end
  end
end
