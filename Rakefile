# frozen_string_literal: true

require 'bundler/gem_tasks'

CLEAN << 'spec/examples.txt'
CLEAN << 'coverage'
CLEAN << 'doc'
CLEAN << '.yardoc'

task default: %i[test lint]

task test: :spec

task lint: :rubocop

task fix: 'rubocop:auto_correct'

begin
  require 'rspec/core/rake_task'
  RSpec::Core::RakeTask.new
rescue LoadError
  nil
end

begin
  require 'rubocop/rake_task'
  RuboCop::RakeTask.new
rescue LoadError
  nil
end

begin
  require 'yard'
  YARD::Rake::YardocTask.new
rescue LoadError
  nil
end
