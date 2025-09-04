# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rake/testtask'

if ENV['BUNDLE_GEMFILE'] == File.expand_path('Gemfile') || ENV['BUNDLE_GEMFILE'].empty? || ENV['BUNDLE_GEMFILE'].nil?
  ENV['BUNDLE_GEMFILE'] = File.expand_path('Gemfile')
end

Rake::TestTask.new(:test) do |t|
  t.libs << 'test'
  t.libs << 'lib'
  file_list = ENV['BUNDLE_GEMFILE'] == File.expand_path('Gemfile') ? FileList['test/**/*_test.rb'] : FileList['test/dependencies/test_dependencies.rb']
  t.test_files = file_list
end

desc 'Run Steep type checking'
task :steep do
  require 'steep'
  require 'steep/cli'

  puts 'Running Steep type check...'
  result = system('bundle', 'exec', 'steep', 'check')
  exit(1) unless result
end

desc 'Run RBS validation'
task :rbs do
  puts 'Validating RBS signatures...'
  result = system('bundle', 'exec', 'rbs', 'validate')
  exit(1) unless result
end

desc 'Run all type checks'
task typecheck: [:rbs, :steep]

task default: :test
