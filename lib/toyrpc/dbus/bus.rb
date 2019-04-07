# frozen_string_literal: true

require 'dbus'

module ToyRPC
  module DBus
    class Bus < ::DBus::Connection
      def initialize(socket_name)
        super
        @service = ServicePool.new
        send_hello
      end

      def request_service(name)
        proxy.RequestName name, NAME_FLAG_REPLACE_EXISTING do |rmsg, r|
          raise rmsg if rmsg.is_a? ::DBus::Error
          unless r == REQUEST_NAME_REPLY_PRIMARY_OWNER
            raise ::DBus::NameRequestError
          end
        end

        @service.add ::DBus::Service.new name, self
      end

    private

      def send_hello
        send_sync hello_message do |rmsg|
          @unique_name = rmsg.destination
          ::DBus.logger.debug \
            "Got hello reply. Our unique_name is #{@unique_name}"
        end

        @service.add ::DBus::Service.new @unique_name, self
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
