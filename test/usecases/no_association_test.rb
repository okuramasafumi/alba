require_relative '../test_helper'

class NoAssociationTest < MiniTest::Test
  class User
    attr_accessor :id, :name, :email, :created_at, :updated_at

    def initialize(id, name, email)
      @id = id
      @name = name
      @email = email
      @created_at = Time.now
      @updated_at = Time.now
    end
  end

  class UserResource
    include Alba::Resource

    attributes :id, :name

    attribute :name_with_email do |resource|
      "#{resource.name}: #{resource.email}"
    end
  end

  class UserResourceWithKeyOnly < UserResource
    key :user
  end

  def setup
    Alba.backend = nil

    @user = User.new(1, 'Masafumi OKURA', 'masafumi@example.com')
  end

  def test_it_returns_correct_json_with_no_opt
    assert_equal(
      '{"id":1,"name":"Masafumi OKURA","name_with_email":"Masafumi OKURA: masafumi@example.com"}',
      UserResource.new(@user).serialize
    )
  end

  def test_it_returns_correct_json_with_serializer_opt
    assert_equal(
      '{"user":{"id":1,"name":"Masafumi OKURA","name_with_email":"Masafumi OKURA: masafumi@example.com"}}',
      UserResourceWithKeyOnly.new(@user).serialize
    )
  end

  def test_it_returns_correct_json_with_with_option_in_serialize_method
    assert_equal(
      '{"user":{"id":1,"name":"Masafumi OKURA","name_with_email":"Masafumi OKURA: masafumi@example.com"}}',
      UserResource.new(@user).serialize(key: :user)
    )
  end

  def test_it_returns_correct_json_with_with_option_in_serialize_method_while_overwriting_default_serializer
    assert_equal(
      '{"user":{"id":1,"name":"Masafumi OKURA","name_with_email":"Masafumi OKURA: masafumi@example.com"}}',
      UserResource.new(@user).serialize(key: :user)
    )
  end

  class UserResource2
    include Alba::Resource

    attribute :name_with_email do |user|
      "#{user.name}: #{user.email}"
    end
  end

  def test_attribute_works_without_block_args
    assert_equal(
      '{"user":{"name_with_email":"Masafumi OKURA: masafumi@example.com"}}',
      UserResource2.new(@user).serialize(key: :user)
    )
  end

  def test_serialiaze_method_with_option_as_proc
    assert_equal(
      '{"user":{"id":1,"name":"Masafumi OKURA","name_with_email":"Masafumi OKURA: masafumi@example.com"}}',
      UserResource.new(@user).serialize(key: :user)
    )
  end

  def test_serialiaze_method_with_option_and_key_is_true
    assert_equal(
      '{"true":{"id":1,"name":"Masafumi OKURA","name_with_email":"Masafumi OKURA: masafumi@example.com"}}',
      UserResource.new(@user).serialize(key: true)
    )
  end

  class UserResourceWithKey
    include Alba::Resource
    attributes :id
    key :not_user
  end

  def test_serializer_key_overwrites_resource_key
    assert_equal(
      '{"user":{"id":1}}',
      UserResourceWithKey.new(@user).serialize(key: :user)
    )
  end
end
