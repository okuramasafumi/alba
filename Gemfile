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
gem 'rubocop', '~> 1.71.0', require: false # For lint
gem 'rubocop-gem_dev', '>= 0.3.0', require: false # For lint
gem 'rubocop-md', '~> 1.0', require: false # For lint
gem 'rubocop-minitest', '~> 0.36.0', require: false # For lint
gem 'rubocop-performance', '~> 1.23.0', require: false # For lint
gem 'rubocop-rake', '~> 0.6.0', require: false # For lint
gem 'simplecov', '~> 0.22.0', require: false # For test coverage
gem 'simplecov-cobertura', require: false # For test coverage
# gem 'steep', require: false # For language server and typing
# gem 'typeprof', require: false # For language server and typing
gem 'yard', require: false # For documentation

# FIXME: There is an upstream JRuby 9.4.9.0 issue with `psych` and the latest
# version of `jar-dependencies`. The issue will be resolved with the release of
# 9.4.10.0. Then, we can remove this `jar-dependencies` dependency lock.
#
# For more information, see: https://github.com/jruby/jruby/issues/8488
#
if defined?(JRUBY_VERSION) && Gem::Version.new(JRUBY_VERSION) < Gem::Version.new('9.4.10.0')
  gem 'jar-dependencies', '< 0.5' # Fix
end

platforms :ruby do
  gem 'oj', '~> 3.11', require: false # For backend
  gem 'ruby-prof', require: false # For performance profiling
end
