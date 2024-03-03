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

task default: :test
