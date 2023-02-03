# Rails integration
require 'rails'
require_relative '../test_helper'
require 'alba/railtie'

class RailtiesTest < MiniTest::Test
  def test_railties
    Alba::Railtie.run_initializers
    assert_equal Alba::DefaultInflector, Alba.inflector
  end
end
