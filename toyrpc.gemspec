# frozen_string_literal: true

lib = File.expand_path('lib', __dir__).freeze
$LOAD_PATH.unshift lib unless $LOAD_PATH.include? lib

require 'toyrpc/version'

Gem::Specification.new do |spec|
  spec.name     = 'toyrpc'
  spec.version  = ToyRPC::VERSION
  spec.license  = 'MIT'
  spec.homepage = 'https://github.com/kotovalexarian/toyrpc'
  spec.summary  = 'Multi-protocol RPC/IPC/MQ client and server in Ruby'
  spec.platform = Gem::Platform::RUBY

  spec.required_ruby_version = '~> 2.6'

  spec.authors = ['Alex Kotov']
  spec.email   = %w[kotovalexarian@gmail.com]

  spec.description = <<~DESCRIPTION
    Multi-protocol RPC/IPC/MQ client and server in Ruby.
  DESCRIPTION

  spec.metadata = {
    'homepage_uri'    => 'https://github.com/kotovalexarian/toyrpc',
    'source_code_uri' => 'https://github.com/kotovalexarian/toyrpc',
    'bug_tracker_uri' => 'https://github.com/kotovalexarian/toyrpc/issues',
  }.freeze

  spec.bindir        = 'exe'
  spec.require_paths = ['lib']

  spec.files = Dir.chdir __dir__ do
    `git ls-files -z`.split("\x0").reject do |f|
      f.match %r{^(examples|test|spec|features)/}
    end
  end

  spec.executables = spec.files.grep %r{^exe/}, &File.method(:basename)

  spec.add_runtime_dependency 'nio4r',     '~> 2.3'
  spec.add_runtime_dependency 'ruby-dbus', '~> 0.15'

  spec.add_development_dependency 'bundler',   '~> 2.0'
  spec.add_development_dependency 'pry',       '~> 0.12'
  spec.add_development_dependency 'pry-doc',   '~> 1.0'
  spec.add_development_dependency 'rake',      '~> 10.0'
  spec.add_development_dependency 'rspec',     '~> 3.8'
  spec.add_development_dependency 'rubocop',   '~> 0.67.2'
  spec.add_development_dependency 'simplecov', '~> 0.16'
  spec.add_development_dependency 'yard',      '~> 0.9'
end
