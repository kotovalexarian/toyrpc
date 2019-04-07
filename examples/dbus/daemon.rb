#!/usr/bin/env ruby
# frozen_string_literal: true

DEFAULT_DBUS_DAEMON_CONFIG_FILE = File.expand_path('config.xml', __dir__).freeze

Kernel.system('dbus-daemon',
              '--nofork',
              '--nopidfile',
              '--nosyslog',
              '--print-address', '',
              '--config-file', DEFAULT_DBUS_DAEMON_CONFIG_FILE)
