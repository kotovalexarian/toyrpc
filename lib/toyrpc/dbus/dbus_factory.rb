# frozen_string_literal: true

module ToyRPC
  module DBus
    module DBusFactory
      DBUS_SERVICE_NAME = 'org.freedesktop.DBus'
      DBUS_OBJECT_PATH  = '/org/freedesktop/DBus'
      DBUS_IFACE_NAME   = 'org.freedesktop.DBus'

    module_function

      def hello_message(sender)
        ::DBus::Message.new(::DBus::Message::METHOD_CALL).tap do |m|
          m.sender      = sender
          m.destination = DBUS_SERVICE_NAME
          m.path        = DBUS_OBJECT_PATH
          m.interface   = DBUS_IFACE_NAME
          m.member      = 'Hello'
        end
      end

      def request_name_message(sender, name, flags)
        ::DBus::Message.new(::DBus::Message::METHOD_CALL).tap do |m|
          m.sender      = sender
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
