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

      def request_service(name)
        dbus_proxy.request_name name, NAME_FLAG_REPLACE_EXISTING do |rmsg, r|
          raise rmsg if rmsg.is_a? ::DBus::Error
          raise NameRequestError unless r == REQUEST_NAME_REPLY_PRIMARY_OWNER
        end

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
        dbus_proxy.hello do |rmsg|
          @unique_name = rmsg.destination
          ::DBus.logger.debug \
            "Got hello reply. Our unique_name is #{@unique_name}"
        end

        service_pool.add ::DBus::Service.new @unique_name, self
      end
    end
  end
end
