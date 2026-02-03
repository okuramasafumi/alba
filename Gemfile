# frozen_string_literal: true

source 'https://rubygems.org'

# Specify your gem's dependencies in alba.gemspec
gemspec

gem 'activesupport', require: false # For backend
gem 'dry-inflector', require: false # For inflection
gem 'ffaker', require: false # For testing
gem 'minitest', '~> 5.14' # For test
gem 'railties', require: false # For Rails integration testing
gem 'rake', '~> 13.0' # For test and automation
gem 'rubocop', '~> 1.84.1', require: false # For lint
gem 'rubocop-gem_dev', '>= 0.3.0', require: false # For lint
gem 'rubocop-md', '~> 2.0', require: false # For lint
gem 'rubocop-minitest', '~> 0.38.0', require: false # For lint
gem 'rubocop-performance', '~> 1.26.0', require: false # For lint
gem 'rubocop-rake', '~> 0.7.1', require: false # For lint
gem 'simplecov', '~> 0.22.0', require: false # For test coverage
gem 'simplecov-cobertura', require: false # For test coverage
gem 'yard', require: false # For documentation

# Type checking gems (not supported on JRuby)
group :type do
  gem 'rbs', '~> 3.0', require: false # For type signatures
  gem 'steep', '~> 1.7.0', require: false # For type checking
end

platforms :ruby do
  gem 'oj', '~> 3.11', require: false # For backend
  gem 'ruby-prof', require: false # For performance profiling
end
