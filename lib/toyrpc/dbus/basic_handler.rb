# frozen_string_literal: true

module ToyRPC
  module DBus
    class BasicHandler
      def method_call(_message); end

      def on_signal(_message); end
    end
  end
end
