require "bundler/gem_tasks"
require "rake/testtask"

ENV["BUNDLE_GEMFILE"] = File.expand_path("Gemfile") if ENV["BUNDLE_GEMFILE"] == File.expand_path("Gemfile") || ENV["BUNDLE_GEMFILE"].empty? || ENV["BUNDLE_GEMFILE"].nil?

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  file_list = ENV["BUNDLE_GEMFILE"] == File.expand_path("Gemfile") ? FileList["test/**/*_test.rb"] : FileList["test/dependencies/test_dependencies.rb"]
  t.test_files = file_list
end

begin
  require 'rspec/core/rake_task'
  RSpec::Core::RakeTask.new(:spec) do |t|
    t.verbose = false
  end

  task 'test:all' => [:test, :spec]
rescue LoadError
  task 'test:all' => [:test]
end

task :default => :'test:all'
