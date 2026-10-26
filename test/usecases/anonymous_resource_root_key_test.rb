# frozen_string_literal: true

require_relative '../test_helper'

class AnonymousResourceRootKeyTest < Minitest::Test
  User = Struct.new(:id)

  def test_root_key_bang_on_anonymous_resource_raises_alba_error
    resource_class = Class.new do
      include Alba::Resource

      root_key!

      attributes :id
    end

    err = with_inflector(:active_support) do
      assert_raises(Alba::Error) { resource_class.new(User.new(1)).serialize }
    end
    assert_equal('An anonymous resource class has no name to derive a root key from. Set the key explicitly.', err.message)
  end

  def test_explicit_root_key_on_anonymous_resource_still_works
    resource_class = Class.new do
      include Alba::Resource

      root_key :user

      attributes :id
    end

    assert_equal('{"user":{"id":1}}', resource_class.new(User.new(1)).serialize)
  end
end
