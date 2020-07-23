require_relative '../test_helper'

class OneTest < MiniTest::Test
  class SerializerWithKey
    include Alba::Serializer

    set key: :foo
  end

  class User
    attr_reader :id, :created_at, :updated_at
    attr_accessor :profile

    def initialize(id)
      @id = id
      @created_at = Time.now
      @updated_at = Time.now
    end
  end

  class Profile
    attr_accessor :user_id, :email, :first_name, :last_name

    def initialize(user_id, email, first_name, last_name)
      @user_id = user_id
      @email = email
      @first_name = first_name
      @last_name = last_name
    end
  end

  class ProfileResource
    include Alba::Resource

    attributes :email

    attribute :full_name do
      "#{first_name} #{last_name}"
    end
  end

  class UserResource1
    include Alba::Resource

    attributes :id

    one :profile, resource: ProfileResource
  end

  def test_it_returns_correct_json_with_resource_option
    user = User.new(1)
    profile = Profile.new(1, 'test@example.com', 'Masafumi', 'Okura')
    user.profile = profile
    assert_equal(
      '{"id":1,"profile":{"email":"test@example.com","full_name":"Masafumi Okura"}}',
      UserResource1.new(user).serialize
    )
  end

  class UserResource2
    include Alba::Resource

    attributes :id

    one :profile do
      attributes :first_name
    end
  end

  def test_it_returns_correct_json_with_block
    user = User.new(1)
    profile = Profile.new(1, 'test@example.com', 'Masafumi', 'Okura')
    user.profile = profile
    assert_equal(
      '{"id":1,"profile":{"first_name":"Masafumi"}}',
      UserResource2.new(user).serialize
    )
  end
end
