# frozen_string_literal: true

require_relative '../test_helper'

class FilteringTest < Minitest::Test
  class User
    attr_accessor :id, :name, :email, :parent_user

    def initialize(id, name, email)
      @id = id
      @name = name
      @email = email
    end
  end

  class UserResource
    include Alba::Resource

    attributes :id, :name, :email

    def select(_k, v)
      !v.nil?
    end
  end

  def setup
    @user1 = User.new(1, nil, nil)
    @user2 = User.new(2, 'OKURA Masafumi', 'masafumi@example.com')
  end

  def test_it_filters_nil_attributes_with_select
    assert_equal(
      '{"id":1}',
      UserResource.new(@user1).serialize
    )
    assert_equal(
      '{"id":2,"name":"OKURA Masafumi","email":"masafumi@example.com"}',
      UserResource.new(@user2).serialize
    )
  end

  class UserResource2 < UserResource
    def select(_key, _value, _attribute)
      true
    end
  end

  def test_it_filters_with_select_with_three_parameters
    assert_equal(
      '{"id":1,"name":null,"email":null}',
      UserResource2.new(@user1).serialize
    )
    assert_equal(
      '{"id":2,"name":"OKURA Masafumi","email":"masafumi@example.com"}',
      UserResource2.new(@user2).serialize
    )
  end

  class UserResourceWithAssociation
    include Alba::Resource

    attributes :id, :name, :email

    one :parent_user do
      attributes :id, :name, :email
    end
  end

  class UserResourceWithAssociationFilteringIt < UserResourceWithAssociation
    def select(_key, _value, attribute)
      !attribute.is_a?(Alba::Association)
    end
  end

  class UserResourceWithAssociationOnlySelectingIt < UserResourceWithAssociation
    def select(_key, _value, attribute)
      attribute.is_a?(Alba::Association)
    end
  end

  def test_it_filters_with_select_with_attribute_parameter
    @user1.parent_user = User.new(2, nil, nil)
    assert_equal(
      '{"id":1,"name":null,"email":null}',
      UserResourceWithAssociationFilteringIt.new(@user1).serialize
    )
    assert_equal(
      '{"parent_user":{"id":2,"name":null,"email":null}}',
      UserResourceWithAssociationOnlySelectingIt.new(@user1).serialize
    )
  end

  class UserResource3
    include Alba::Resource

    attributes :id, :name

    nested :special do
      attributes :email
    end

    def select(_k, v)
      !v.nil?
    end
  end

  def test_it_filters_attributes_in_nested_attributes
    assert_equal(
      '{"id":1,"special":{}}',
      UserResource3.new(@user1).serialize
    )
    assert_equal(
      '{"id":2,"name":"OKURA Masafumi","special":{"email":"masafumi@example.com"}}',
      UserResource3.new(@user2).serialize
    )
    # Here `select` is not leaked
    result = Alba.serialize(@user2) do
      attributes :id, :name

      nested :special do
        attributes :email
      end
    end
    assert_equal(
      '{"id":2,"name":"OKURA Masafumi","special":{"email":"masafumi@example.com"}}',
      result
    )
  end

  class UserResource4
    include Alba::Resource

    attributes :id, :name

    trait :my_trait do
      attributes :email
    end

    def select(_k, v)
      !v.nil?
    end
  end

  def test_it_filters_attributes_in_trait
    assert_equal(
      '{"id":1}',
      UserResource4.new(@user1, with_traits: :my_trait).serialize
    )
    assert_equal(
      '{"id":1}',
      UserResource4.new(@user1).serialize
    )
    assert_equal(
      '{"id":2,"name":"OKURA Masafumi","email":"masafumi@example.com"}',
      UserResource4.new(@user2, with_traits: :my_trait).serialize
    )
  end
end
