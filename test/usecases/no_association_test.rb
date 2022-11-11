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
    root_key :user
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

  def test_it_does_not_print_warnings_when_root_key_is_called
    assert_silent do
      Class.new do
        include Alba::Resource

        root_key :foo
      end
    end
  end

  def test_it_does_not_print_warnings_when_root_key_bang_is_called
    assert_silent do
      Class.new do
        include Alba::Resource

        root_key!
      end
    end
  end

  class UserResourceWithRootKey < UserResource
    root_key :user, :users
  end

  def test_it_returns_json_with_second_argument_to_root_key_as_key_for_collection
    assert_equal(
      '{"users":[{"id":1,"name":"Masafumi OKURA","name_with_email":"Masafumi OKURA: masafumi@example.com"}]}',
      UserResourceWithRootKey.new([@user]).serialize
    )
  end

  def test_it_returns_correct_json_with_with_root_key_option_to_serialize_method
    assert_equal(
      '{"user":{"id":1,"name":"Masafumi OKURA","name_with_email":"Masafumi OKURA: masafumi@example.com"}}',
      UserResource.new(@user).serialize(root_key: :user)
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
      UserResource2.new(@user).serialize(root_key: :user)
    )
  end

  def test_serialiaze_method_with_option_as_proc
    assert_equal(
      '{"user":{"id":1,"name":"Masafumi OKURA","name_with_email":"Masafumi OKURA: masafumi@example.com"}}',
      UserResource.new(@user).serialize(root_key: :user)
    )
  end

  def test_serialiaze_method_with_option_and_key_is_true
    assert_equal(
      '{"true":{"id":1,"name":"Masafumi OKURA","name_with_email":"Masafumi OKURA: masafumi@example.com"}}',
      UserResource.new(@user).serialize(root_key: true)
    )
  end

  class UserResourceWithKey
    include Alba::Resource
    attributes :id
    root_key :not_user
  end

  def test_serializer_key_overwrites_resource_key
    assert_equal(
      '{"user":{"id":1}}',
      UserResourceWithKey.new(@user).serialize(root_key: :user)
    )
  end

  def test_it_raises_argument_error_with_attribute_without_block
    resource = <<~RUBY
      class InvalidResource
        include Alba::Resource

        attribute :without_block
      end
    RUBY
    assert_raises(ArgumentError) { eval(resource) }
  end

  class UserFilteringResource
    include Alba::Resource

    root_key :user

    attributes :id, :name

    def select(_key, value)
      !value.nil?
    end
  end

  def test_it_filters_attributes
    user = User.new(1, nil, 'test@example.com')

    assert_equal(
      '{"user":{"id":1}}',
      UserFilteringResource.new(user).serialize
    )
  end
end
