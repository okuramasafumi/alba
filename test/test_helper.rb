require 'simplecov'

require 'simplecov-cobertura'

if ENV['CI']
  SimpleCov.formatter = SimpleCov::Formatter::CoberturaFormatter
  SimpleCov.start do
    add_filter '/test/'
  end
else
  SimpleCov.start do
    add_filter '/test/'
    enable_coverage :branch
    primary_coverage :branch
  end
end

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
require 'alba'

require 'minitest/autorun'
