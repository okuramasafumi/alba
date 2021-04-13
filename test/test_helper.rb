require 'simplecov'
SimpleCov.start do
  enable_coverage :branch
  primary_coverage :branch
end

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
require 'alba'
if ENV['OS'] != 'Windows_NT' && RUBY_PLATFORM !~ /java/
  require 'oj' # For backend swapping
end

require 'minitest/autorun'
