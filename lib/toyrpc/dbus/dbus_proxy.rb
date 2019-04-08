# frozen_string_literal: true

module ToyRPC
  module DBus
    class DBusProxy < BasicProxy
      DBUS_SERVICE_NAME = 'org.freedesktop.DBus'
      DBUS_OBJECT_PATH  = '/org/freedesktop/DBus'
      DBUS_IFACE_NAME   = 'org.freedesktop.DBus'

      def hello
        bus.send_sync hello_message do |return_message|
          raise return_message if return_message.is_a? ::DBus::Error

          return String(return_message.destination)
        end
        nil
      end

      def getid
        String(Array(bus.send_sync_or_async(getid_message)).first).freeze
      end

      def request_name(name, flags, &block)
        bus.send_sync_or_async(request_name_message(name, flags), &block)
        nil
      end

    private

      def hello_message
        ::DBus::Message.new(::DBus::Message::METHOD_CALL).tap do |m|
          m.sender      = bus.unique_name
          m.destination = DBUS_SERVICE_NAME
          m.path        = DBUS_OBJECT_PATH
          m.interface   = DBUS_IFACE_NAME
          m.member      = 'Hello'
        end
      end

      def getid_message
        ::DBus::Message.new(::DBus::Message::METHOD_CALL).tap do |m|
          m.sender      = bus.unique_name
          m.destination = DBUS_SERVICE_NAME
          m.path        = DBUS_OBJECT_PATH
          m.interface   = DBUS_IFACE_NAME
          m.member      = 'GetId'
        end
      end

      def request_name_message(name, flags)
        ::DBus::Message.new(::DBus::Message::METHOD_CALL).tap do |m|
          m.sender      = bus.unique_name
          m.destination = DBUS_SERVICE_NAME
          m.path        = DBUS_OBJECT_PATH
          m.interface   = DBUS_IFACE_NAME
          m.member      = 'RequestName'

          m.add_param 's', String(name)
          m.add_param 'u', flags
        end
      end
    end
  end
end
