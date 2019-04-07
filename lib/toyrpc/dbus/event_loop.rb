# frozen_string_literal: true

module ToyRPC
  module DBus
    class EventLoop
      def initialize
        @main = ::DBus::Main.new
      end

      def <<(bus)
        @main << bus
        nil
      end

      def stop
        @main.quit
        nil
      end

      def run
        @main.run
        nil
      end
    end
  end
end
