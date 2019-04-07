# frozen_string_literal: true

require 'dbus'

module ToyRPC
  module DBus
    class Object
      attr_reader :path, :intfs
      attr_writer :service

      def initialize(path, handler, intfs)
        @path = path
        @handler = handler
        @intfs = intfs
        @service = nil
      end

      def dispatch(dbus_message)
        return unless dbus_message.message_type == ::DBus::Message::METHOD_CALL

        @service.bus.message_queue.push(reply(dbus_message))
      end

    private

      def reply(dbus_message)
        method_info = get_method_info(dbus_message)
        result = [*@handler.method(method_info.name).call(*dbus_message.params)]
        reply = ::DBus::Message.method_return(dbus_message)
        method_info.outs.map(&:type).zip(result).each do |type, data|
          reply.add_param(type.to_s, data)
        end
        reply
      rescue StandardError => e
        ::DBus::ErrorMessage.from_exception(dbus_message.annotate_exception(e))
                            .reply_to(dbus_message)
      end

      def get_method_info(dbus_message)
        dbus_object_path    = dbus_message.path.to_s
        dbus_interface_name = dbus_message.interface.to_sym
        dbus_method_name    = dbus_message.member.to_sym

        if intfs[dbus_interface_name].nil?
          raise(
            ::DBus.error('org.freedesktop.DBus.Error.UnknownMethod'),
            "Interface \"#{dbus_interface_name}\" " \
            "of object \"#{dbus_object_path}\" doesn't exist",
          )
        end

        if intfs[dbus_interface_name].methods[dbus_method_name].nil?
          raise(
            ::DBus.error('org.freedesktop.DBus.Error.UnknownMethod'),
            "Method \"#{dbus_method_name}\" " \
            "on interface \"#{dbus_interface_name}\" " \
            "of object \"#{dbus_object_path}\" doesn't exist",
          )
        end

        intfs[dbus_interface_name].methods[dbus_method_name]
      end
    end
  end
end
