# frozen_string_literal: true

require 'toyrpc/version'

##
# Modern modular JSON-RPC client and server in Ruby.
#
module ToyRPC
  DEFAULT_DBUS_DAEMON_CONFIG_FILE = File.expand_path(
    File.join('..', 'fixtures', 'default.dbus.xml'),
    __dir__,
  ).freeze

  def self.dbus_daemon(config_file = DEFAULT_DBUS_DAEMON_CONFIG_FILE)
    Kernel.system('dbus-daemon',
                  '--nofork',
                  '--nopidfile',
                  '--nosyslog',
                  '--print-address', '',
                  '--print-pid', '',
                  '--config-file', config_file)
  end
end
