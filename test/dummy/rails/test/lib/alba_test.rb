require_relative '../test_helper'

class AlbaTest < Minitest::Test
  def test_default_inflector_is_set_automatically
    assert_equal Alba::DefaultInflector, Alba.inflector
  end

  # def test_default_inflector_can_be_changed_to_active_support
  #   Alba.inflector = :active_support

  #   assert_equal Alba::DefaultInflector, Alba.inflector
  # end

  # def test_default_inflector_can_be_changed_to_dry_inflector
  #   Alba.inflector = :dry

  #   assert_equal Dry::Inflector, Alba.inflector.class
  # end

  # def test_initializer_can_be_unset
  #   Alba.inflector = nil

  #   assert_nil Alba.inflector
  # end
end
