require_relative '../test_helper'

class TypedAttributesTest < MiniTest::Test
  class User
    attr_accessor :id, :name, :email, :created_at, :updated_at

    def initialize(id, name, email)
      @id = id
      @name = name
      @email = email
      @created_at = Time.new(2020, 1, 1)
      @updated_at = Time.new(2020, 1, 1)
    end
  end

  class UserResource
    include Alba::Resource

    attributes :id, String, :name, :email, :created_at, ->(time) { time.strftime('%F') }
  end

  def setup
    Alba.backend = nil

    @user = User.new(1, 'Masafumi OKURA', 'masafumi@example.com')
  end

  def test_it_serializes_with_given_types
    assert_equal('{"id":"1","name":"Masafumi OKURA","email":"masafumi@example.com","created_at":"2020-01-01"}', UserResource.new(@user).serialize)
  end
end
