# frozen_string_literal: true

require 'concurrent'
require 'dbus'

require 'toyrpc/dbus/address'
require 'toyrpc/dbus/basic_handler'
require 'toyrpc/dbus/basic_proxy'
require 'toyrpc/dbus/bus'
require 'toyrpc/dbus/dbus_proxy'
require 'toyrpc/dbus/gateway'
require 'toyrpc/dbus/manager'
require 'toyrpc/dbus/message'
require 'toyrpc/dbus/unix_connection'

module ToyRPC
  module DBus
    NAME_FLAG_ALLOW_REPLACEMENT = 0x1
    NAME_FLAG_REPLACE_EXISTING  = 0x2
    NAME_FLAG_DO_NOT_QUEUE      = 0x4

    REQUEST_NAME_REPLY_PRIMARY_OWNER = 0x1
    REQUEST_NAME_REPLY_IN_QUEUE      = 0x2
    REQUEST_NAME_REPLY_EXISTS        = 0x3
    REQUEST_NAME_REPLY_ALREADY_OWNER = 0x4
  end
end
