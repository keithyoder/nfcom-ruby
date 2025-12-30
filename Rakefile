# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

require 'rubocop/rake_task'

RuboCop::RakeTask.new

# Bundler Audit task
desc 'Run bundler-audit to check for vulnerable dependencies'
task :audit do
  require 'bundler/audit/cli'
  Bundler::Audit::CLI.start(['check', '--update'])
rescue LoadError
  warn 'bundler-audit not available. Install it with: gem install bundler-audit'
end

task default: %i[spec rubocop]
task ci: %i[spec rubocop audit]
