#!/usr/bin/env rake
require "bundler/gem_tasks"

require 'rspec/core/rake_task'
desc 'Default: run specs.'
task :default => :spec

desc "Run specs"
RSpec::Core::RakeTask.new

task :test do
  fail %q{This application uses RSpec. Try running "rake spec"}
end
