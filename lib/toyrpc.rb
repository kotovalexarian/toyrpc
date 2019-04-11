# frozen_string_literal: true

require 'toyrpc/version'

require 'toyrpc/connections/buffer'
require 'toyrpc/connections/unix'

module ToyRPC
  class BufferOverflowError < StandardError; end
end
