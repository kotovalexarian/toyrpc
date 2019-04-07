# frozen_string_literal: true

require 'dbus'

module ToyRPC
  module DBus
    class Bus < ::DBus::Connection
      def initialize(socket_name)
        super
        @service = service_pool
        send_hello
      end

      def request_service(name)
        proxy.RequestName name, NAME_FLAG_REPLACE_EXISTING do |rmsg, r|
          raise rmsg if rmsg.is_a? ::DBus::Error
          raise NameRequestError unless r == REQUEST_NAME_REPLY_PRIMARY_OWNER
        end

        service_pool.add ::DBus::Service.new name, self
      end

    private

      def service_pool
        @service_pool ||= ServicePool.new
      end

      def proxy
        @proxy ||= ::DBus::ProxyObjectFactory.new(
          DBUSXMLINTRO,
          self,
          'org.freedesktop.DBus',
          '/org/freedesktop/DBus',
          api: ::DBus::ApiOptions::A0,
        ).build['org.freedesktop.DBus']
      end

      def send_hello
        send_sync hello_message do |rmsg|
          @unique_name = rmsg.destination
          ::DBus.logger.debug \
            "Got hello reply. Our unique_name is #{@unique_name}"
        end

        service_pool.add ::DBus::Service.new @unique_name, self
      end

      def hello_message
        ::DBus::Message.new(::DBus::Message::METHOD_CALL).tap do |m|
          m.destination = 'org.freedesktop.DBus'
          m.path = '/org/freedesktop/DBus'
          m.interface = 'org.freedesktop.DBus'
          m.member = 'Hello'
        end
      end
    end
  end
end
