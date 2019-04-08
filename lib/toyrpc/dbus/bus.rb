# frozen_string_literal: true

module ToyRPC
  module DBus
    class Bus < ::DBus::Connection
      def initialize(socket_name)
        super
        @service = service_pool
        send_hello
      end

      def daemon_id
        @daemon_id ||= dbus_proxy.getid
      end

      def add_service(name)
        service_pool.add ::DBus::Service.new name, self
      end

    private

      def service_pool
        @service_pool ||= ServicePool.new
      end

      def dbus_proxy
        @dbus_proxy ||= DBusProxy.new self
      end

      def send_hello
        @unique_name = dbus_proxy.hello
        ::DBus.logger.debug "Got hello reply. Our unique_name is #{unique_name}"
        service_pool.add ::DBus::Service.new unique_name, self
      end
    end
  end
end
