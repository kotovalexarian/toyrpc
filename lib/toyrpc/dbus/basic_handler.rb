# frozen_string_literal: true

module ToyRPC
  module DBus
    class BasicHandler
      def process_call(_message); end

      def process_signal(_message); end
    end
  end
end
