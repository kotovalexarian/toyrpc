# frozen_string_literal: true

module ToyRPC
  module DBus
    class Bus < ::DBus::Connection
      DBUS_SERVICE_NAME = 'org.freedesktop.DBus'
      DBUS_OBJECT_PATH  = '/org/freedesktop/DBus'
      DBUS_IFACE_NAME   = 'org.freedesktop.DBus'

      DBUSXMLINTRO = File.read(
        File.expand_path(
          File.join('..', '..', '..', 'share', 'dbus.xml'),
          __dir__,
        ),
      ).freeze

      def initialize(socket_name)
        super
        @service = service_pool
        send_hello
      end

      def daemon_id
        @daemon_id ||= begin
          call_message = ::DBus::Message.new ::DBus::Message::METHOD_CALL
          call_message.sender = nil
          call_message.destination = DBUS_SERVICE_NAME
          call_message.path = DBUS_OBJECT_PATH
          call_message.interface = DBUS_IFACE_NAME
          call_message.member = 'GetId'

          result = send_sync_or_async(call_message)

          String(Array(result).first).freeze
        end
      end

      def request_service(name)
        call_message = ::DBus::Message.new ::DBus::Message::METHOD_CALL
        call_message.sender = @unique_name
        call_message.destination = DBUS_SERVICE_NAME
        call_message.path = DBUS_OBJECT_PATH
        call_message.interface = DBUS_IFACE_NAME
        call_message.member = 'RequestName'
        call_message.add_param 's', name
        call_message.add_param 'u', NAME_FLAG_REPLACE_EXISTING

        send_sync_or_async call_message do |rmsg, r|
          raise rmsg if rmsg.is_a? ::DBus::Error
          raise NameRequestError unless r == REQUEST_NAME_REPLY_PRIMARY_OWNER
        end

        service_pool.add ::DBus::Service.new name, self
      end

    private

      def service_pool
        @service_pool ||= ServicePool.new
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
          m.destination = DBUS_SERVICE_NAME
          m.path        = DBUS_OBJECT_PATH
          m.interface   = DBUS_IFACE_NAME
          m.member      = 'Hello'
        end
      end
    end
  end
end
