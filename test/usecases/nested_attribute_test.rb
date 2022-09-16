require_relative '../test_helper'

class NestedAttributeTest < MiniTest::Test
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

    @user = User.new(1, 'Masafumi OKURA', 'masafumi@example.com', 'Tokyo', '0000000')
  end

  def test_nested_attribute_becomes_nested_hash
    assert_equal '{"user":{"id":1,"address":{"city":"Tokyo","zipcode":"0000000"}}}', UserResource.new(@user).serialize
  end

  class Foo
    def initialize(bar, baz)
      @bar = bar
      @baz = baz
    end
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
end
