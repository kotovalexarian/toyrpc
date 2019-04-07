#!/usr/bin/env ruby
# frozen_string_literal: true

DEFAULT_DBUS_DAEMON_CONFIG_FILE = File.expand_path(
  File.join('..', '..', 'fixtures', 'default.dbus.xml'),
  __dir__,
).freeze

Kernel.system('dbus-daemon',
              '--nofork',
              '--nopidfile',
              '--nosyslog',
              '--print-address', '',
              '--print-pid', '',
              '--config-file', DEFAULT_DBUS_DAEMON_CONFIG_FILE)
