# frozen_string_literal: true

require 'dbus'

module ToyRPC
  module DBus
    class Bus < ::DBus::Connection
      def initialize(socket_name)
        super
        send_hello
      end
    end
  end
end
