require "bundler/gem_tasks"
require "rspec/core/rake_task"
require "rubocop/rake_task"

RSpec::Core::RakeTask.new(:spec)

task default: [:spec, :rubocop]

desc "Run RuboCop checks"
RuboCop::RakeTask.new
