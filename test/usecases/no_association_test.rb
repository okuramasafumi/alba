require_relative '../test_helper'

class NoAssociationTest < MiniTest::Test
  class SerializerWithKey
    include Alba::Serializer

    set key: :user
  end

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

  class UserResourceWithSerializerOpt < UserResource
    serializer SerializerWithKey
  end

  def setup
    Alba.backend = nil
    Alba.default_serializer = nil

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
      UserResourceWithSerializerOpt.new(@user).serialize
    )
  end

  def test_it_returns_correct_json_with_with_option_in_serialize_method
    assert_equal(
      '{"user":{"id":1,"name":"Masafumi OKURA","name_with_email":"Masafumi OKURA: masafumi@example.com"}}',
      UserResource.new(@user).serialize(with: SerializerWithKey)
    )
  end

  def test_it_returns_correct_json_with_with_option_in_serialize_method_while_overwriting_default_serializer
    Alba.default_serializer = proc { set key: :overwrite_me }

    assert_equal(
      '{"user":{"id":1,"name":"Masafumi OKURA","name_with_email":"Masafumi OKURA: masafumi@example.com"}}',
      UserResource.new(@user).serialize(with: SerializerWithKey)
    )
  end

  class UserResource2
    include Alba::Resource

    attribute :name_with_email do
      "#{name}: #{email}"
    end
  end

  def test_attribute_works_without_block_args
    assert_equal(
      '{"user":{"name_with_email":"Masafumi OKURA: masafumi@example.com"}}',
      UserResource2.new(@user).serialize(with: SerializerWithKey)
    )
  end

  def test_serialiaze_method_with_option_as_proc
    assert_equal(
      '{"user":{"id":1,"name":"Masafumi OKURA","name_with_email":"Masafumi OKURA: masafumi@example.com"}}',
      UserResource.new(@user).serialize(with: proc { set key: :user })
    )
  end
end
