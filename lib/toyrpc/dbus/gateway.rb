# frozen_string_literal: true

module ToyRPC
  module DBus
    class Gateway
      attr_reader :bus

      def initialize(address, handler)
        self.address = address

        @bus = Bus.new address, handler

        @proxies_mutex = Mutex.new
        @proxies = {}
      end

      def proxy(name)
        unless name.instance_of? Symbol
          raise TypeError, "Expected #{Symbol}, got #{name}"
        end

        @proxies[name] or raise "Unknown proxy: #{name.to_s.inspect}"
      end

      def add_proxy(name)
        unless name.instance_of? Symbol
          raise TypeError, "Expected #{Symbol}, got #{name.class}"
        end

        @proxies_mutex.synchronize do
          unless @proxies[name].nil?
            raise "Proxy name already in use: #{name.to_s.inspect}"
          end

          @proxies[name] = yield bus
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
