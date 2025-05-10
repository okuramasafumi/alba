# frozen_string_literal: true

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
    @original_inflector = Alba.inflector
    Alba.backend = nil
    Alba.inflector = :active_support

    @user = User.new(1, 'Masafumi OKURA', 'masafumi@example.com', 'Tokyo', '0000000')
  end

  def teardown
    Alba.inflector = @original_inflector
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

  def test_raising_error_without_block
    assert_raises(ArgumentError) do
      Class.new do
        include Alba::Resource

        nested_attribute :foo
      end
    end
  end

  class Bar2Resource
    include Alba::Resource

    transform_keys :camel, cascade: false

    nested_attribute :na do
      attributes :some_value
    end
  end

  def test_without_key_transformation_cascade
    assert_equal(
      '{"Na":{"some_value":"foo"}}',
      Bar2Resource.new(Bar.new('foo')).serialize
    )
  end

  class Bar3Resource
    include Alba::Resource

    nested_attribute :na, if: proc { |bar, _| bar.some_value == 'foo' } do
      attributes :some_value
    end
  end

  def test_conditional_nested_attribute
    assert_equal(
      '{"na":{"some_value":"foo"}}',
      Bar3Resource.new(Bar.new('foo')).serialize
    )
    assert_equal(
      '{}',
      Bar3Resource.new(Bar.new('foo!')).serialize
    )
  end

  # TODO: Fix this test
  # class Bar3Resource
  #   include Alba::Resource
  #
  #   nested_attribute :na do
  #     attributes :some_value
  #   end
  #
  #   def some_value(_object)
  #     'From resource method'
  #   end
  # end
  #
  # def test_nested_attribute_with_resource_method
  #   assert_equal(
  #     '{"na":{"some_value":"From resource method"}}',
  #     Bar3Resource.new(Bar.new('foo')).serialize
  #   )
  # end
end
