require_relative '../test_helper'

class NestedAttributeTest < Minitest::Test
  class User
    attr_accessor :id, :name, :email, :city, :zipcode

    def initialize(id, name, email, city, zipcode)
      @id = id
      @name = name
      @email = email
      @city = city
      @zipcode = zipcode
    end
  end

  class UserResource
    include Alba::Resource

    root_key :user

    attributes :id

    nested_attribute :address do
      attributes :city, :zipcode
    end
  end

  def setup
    Alba.backend = nil
    Alba.inflector = :active_support

    @user = User.new(1, 'Masafumi OKURA', 'masafumi@example.com', 'Tokyo', '0000000')
  end

  def teardown
    Alba.inflector = nil
  end

  def test_nested_attribute_becomes_nested_hash
    assert_equal '{"user":{"id":1,"address":{"city":"Tokyo","zipcode":"0000000"}}}', UserResource.new(@user).serialize
  end

  class FooResource
    include Alba::Resource

    root_key :foo

    nested :bar do
      nested :baz do
        attribute :deep do
          42
        end
      end
    end
  end

  def test_deeply_nested_attribute
    assert_equal(
      '{"foo":{"bar":{"baz":{"deep":42}}}}',
      FooResource.new(nil).serialize
    )
  end

  Bar = Struct.new(:some_value)

  class BarResource
    include Alba::Resource

    transform_keys :camel

    nested_attribute :na do
      attributes :some_value
    end
  end

  def test_key_transformation_cascades_with_nested_attribute
    assert_equal(
      '{"Na":{"SomeValue":"foo"}}',
      BarResource.new(Bar.new('foo')).serialize
    )
  end
end
