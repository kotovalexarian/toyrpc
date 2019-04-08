# frozen_string_literal: true

module ToyRPC
  module DBus
    class Object
      attr_reader :intfs

      def initialize(handler, intfs)
        @handler = handler
        @intfs = intfs
      end

      def reply(dbus_message)
        method_info = get_method_info(dbus_message)
        result = [*@handler.method(method_info.to).call(*dbus_message.params)]
        Message.reply_to(
          dbus_message,
          method_info.outs.map(&:type).zip(result),
        )
      rescue => e
        Message.reply_with_exception(dbus_message, e)
      end

    private

      def get_method_info(dbus_message)
        dbus_object_path    = dbus_message.path.to_s
        dbus_interface_name = dbus_message.interface.to_sym
        dbus_method_name    = dbus_message.member.to_sym

        dbus_interface = get_interface_info(dbus_message)

        if dbus_interface.methods[dbus_method_name].nil?
          raise(
            ::DBus.error('org.freedesktop.DBus.Error.UnknownMethod'),
            "Method \"#{dbus_method_name}\" " \
            "on interface \"#{dbus_interface_name}\" " \
            "of object \"#{dbus_object_path}\" doesn't exist",
          )
        end

        dbus_interface.methods[dbus_method_name]
      end

      def get_interface_info(dbus_message)
        dbus_object_path    = dbus_message.path.to_s
        dbus_interface_name = dbus_message.interface.to_sym

        if intfs[dbus_interface_name].nil?
          raise(
            ::DBus.error('org.freedesktop.DBus.Error.UnknownMethod'),
            "Interface \"#{dbus_interface_name}\" " \
            "of object \"#{dbus_object_path}\" doesn't exist",
          )
        end

        intfs[dbus_interface_name]
      end
    end
  end
end
