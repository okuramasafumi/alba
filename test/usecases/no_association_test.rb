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

  def test_it_returns_correct_json_with_no_opt
    user = User.new(1, 'Masafumi OKURA', 'masafumi@example.com')
    assert_equal(
      {
        id: 1,
        name: 'Masafumi OKURA',
        name_with_email: 'Masafumi OKURA: masafumi@example.com'
      }.to_json,
      UserResource.new(user).serialize
    )
  end

  def test_it_returns_correct_json_with_serializer_opt
    user = User.new(1, 'Masafumi OKURA', 'masafumi@example.com')
    assert_equal(
      {
        user: {
          id: 1,
          name: 'Masafumi OKURA',
          name_with_email: 'Masafumi OKURA: masafumi@example.com'
        }
      }.to_json,
      UserResourceWithSerializerOpt.new(user).serialize
    )
  end

  def test_it_returns_correct_json_with_with_option_in_serialize_method
    user = User.new(1, 'Masafumi OKURA', 'masafumi@example.com')
    assert_equal(
      {
        user: {
          id: 1,
          name: 'Masafumi OKURA',
          name_with_email: 'Masafumi OKURA: masafumi@example.com'
        }
      }.to_json,
      UserResource.new(user).serialize(with: SerializerWithKey)
    )
  end

  class UserResource2
    include Alba::Resource

    attribute :name_with_email do
      "#{name}: #{email}"
    end
  end

  def test_attribute_works_without_block_args
    user = User.new(1, 'Masafumi OKURA', 'masafumi@example.com')
    assert_equal(
      '{"user":{"name_with_email":"Masafumi OKURA: masafumi@example.com"}}',
      UserResource2.new(user).serialize(with: SerializerWithKey)
    )
  end
end
