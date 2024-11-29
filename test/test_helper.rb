# frozen_string_literal: true

require 'simplecov'

require 'simplecov-cobertura'

SimpleCov.formatter = SimpleCov::Formatter::CoberturaFormatter if ENV['CI']
SimpleCov.start do
  add_filter '/test/'
  enable_coverage :branch
  primary_coverage :branch
end

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
require 'alba'

require 'minitest/autorun'

class Minitest::Test # rubocop:disable Style/ClassAndModuleChildren
  def with_inflector(inflector = :active_support)
    original_inflector = Alba.inflector
    Alba.inflector = inflector
    yield
  ensure
    Alba.inflector = original_inflector
  end
end
