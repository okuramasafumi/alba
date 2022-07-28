require 'simplecov'

require 'active_support'
require 'active_support/core_ext/object/json'
require 'alba'
require 'alba/jsonapi'
require 'ffaker'
require 'rspec'
require 'jsonapi/rspec'
require 'securerandom'

Dir[File.expand_path('spec/fixtures/*.rb')].sort.each { |f| require f }

RSpec.configure do |config|
  config.include JSONAPI::RSpec

  config.mock_with(:rspec)
  config.filter_run_when_matching(:focus)
  config.disable_monkey_patching!

  config.expect_with(:rspec) do |c|
    c.syntax = :expect
  end
end
