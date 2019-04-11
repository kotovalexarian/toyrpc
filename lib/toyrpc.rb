# frozen_string_literal: true

require 'toyrpc/version'

require 'toyrpc/connections/buffer'
require 'toyrpc/connections/unix'

require 'fcntl'
require 'socket'

module ToyRPC
  class BufferOverflowError < StandardError; end
end
