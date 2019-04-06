# frozen_string_literal: true

lib = File.expand_path('lib', __dir__).freeze
$LOAD_PATH.unshift lib unless $LOAD_PATH.include? lib

require 'toyrpc/version'

Gem::Specification.new do |spec|
  spec.name     = 'toyrpc'
  spec.version  = Toyrpc::VERSION
  spec.license  = 'MIT'
  spec.homepage = 'https://github.com/kotovalexarian/toyrpc'
  spec.summary  = 'Modern modular JSON-RPC client and server in Ruby.'
  spec.platform = Gem::Platform::RUBY

  spec.required_ruby_version = '~> 2.6'

  spec.authors = ['Alex Kotov']
  spec.email   = %w[kotovalexarian@gmail.com]

  spec.description = <<~DESCRIPTION
    Modern modular JSON-RPC client and server in Ruby.'
  DESCRIPTION

  spec.metadata = {
    'homepage_uri'    => 'https://github.com/kotovalexarian/toyrpc',
    'source_code_uri' => 'https://github.com/kotovalexarian/toyrpc',
    'bug_tracker_url' => 'https://github.com/kotovalexarian/toyrpc/issues',
  }.freeze

  spec.bindir        = 'exe'
  spec.require_paths = ['lib']

  spec.files = Dir.chdir __dir__ do
    `git ls-files -z`.split("\x0").reject do |f|
      f.match %r{^(test|spec|features)/}
    end
  end

  spec.executables = spec.files.grep %r{^exe/}, &File.method(:basename)

  spec.add_development_dependency 'bundler', '~> 2.0'
  spec.add_development_dependency 'rake',    '~> 10.0'
end
