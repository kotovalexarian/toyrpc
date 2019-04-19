# frozen_string_literal: true

require_relative 'toyrpc/version'

require_relative 'toyrpc/connections/buffer'
require_relative 'toyrpc/connections/unix'

require 'fcntl'
require 'socket'

module ToyRPC
  class BufferOverflowError < StandardError; end
end
