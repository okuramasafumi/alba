# frozen_string_literal: true

require_relative '../test_helper'

class NilFilteringTest < Minitest::Test
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

    def select(_k, v) # rubocop:disable Naming/MethodParameterName
      !v.nil?
    end
  end

  def setup
    @user = User.new(1, nil, nil)
  end

  def test_it_filters_nil_attributes_with_select
    assert_equal(
      '{"id":1}',
      UserResource.new(@user).serialize
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
      UserResource2.new(@user).serialize
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
    @user.parent_user = User.new(2, nil, nil)
    assert_equal(
      '{"id":1,"name":null,"email":null}',
      UserResourceWithAssociationFilteringIt.new(@user).serialize
    )
    assert_equal(
      '{"parent_user":{"id":2,"name":null,"email":null}}',
      UserResourceWithAssociationOnlySelectingIt.new(@user).serialize
    )
  end
end
