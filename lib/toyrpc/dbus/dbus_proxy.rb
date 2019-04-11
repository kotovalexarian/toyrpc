# frozen_string_literal: true

module ToyRPC
  module DBus
    class DBusProxy < BasicProxy
      include DBusFactory

      def hello(&block)
        bus.send_async hello_message(bus.unique_name), &block
        nil
      end

      def request_name(name, flags, &block)
        bus.send_async request_name_message(bus.unique_name, name, flags),
                       &block
        nil
      end
    end
  end
end
