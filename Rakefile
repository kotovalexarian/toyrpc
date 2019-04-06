# frozen_string_literal: true

require 'bundler/gem_tasks'

task default: :rubocop

task fix: 'rubocop:auto_correct'

begin
  require 'rubocop/rake_task'
  RuboCop::RakeTask.new
rescue LoadError
  nil
end
