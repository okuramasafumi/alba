# Rails integration
require 'rails'
require_relative '../test_helper'
require 'alba/railtie'

class RailtiesTest < Minitest::Test
  def test_railties
    Alba::Railtie.run_initializers
    assert_equal Alba::DefaultInflector, Alba.inflector
  end

  def test_rails_controller_integration
    require 'action_controller'
    Alba::Railtie.run_initializers

    controller = Class.new(ActionController::Base)
    assert_includes controller.instance_methods, :serialize
  end
end
