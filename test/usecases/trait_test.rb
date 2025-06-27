# frozen_string_literal: true

require_relative '../test_helper'

class TraitTest < Minitest::Test
  User = Struct.new(:id, :name, :email, :profile)
  Profile = Struct.new(:user_id, :bio, :status)

  class UserResource
    include Alba::Resource

    attributes :id

    trait :name_and_email do
      attributes :name, :email
    end
  end

  class ProfileResource
    include Alba::Resource

    attributes :bio

    trait :with_status do
      attributes :status
    end
  end

  def setup
    @user = User.new(1, 'Masafumi OKURA', 'masafumi@example.com')
    @user.profile = Profile.new(1, 'Software Engineer at Example Corp', :active)
  end

  def test_it_does_not_return_in_trait_if_not_specified
    assert_equal(
      '{"id":1}',
      UserResource.new(@user).serialize
    )
  end

  def test_it_returns_in_trait_if_specified
    assert_equal(
      '{"id":1,"name":"Masafumi OKURA","email":"masafumi@example.com"}',
      UserResource.new(@user, with_traits: :name_and_email).serialize
    )
    assert_equal(
      '{"id":1,"name":"Masafumi OKURA","email":"masafumi@example.com"}',
      UserResource.new(@user, with_traits: [:name_and_email]).serialize
    )
  end

  def test_traits_for_collection
    users = [
      User.new(1, 'Foo', 'foo@example.org'),
      User.new(2, 'Bar', 'bar@example.org')
    ]
    assert_equal(
      '[{"id":1},{"id":2}]',
      UserResource.new(users).serialize
    )
    assert_equal(
      '[{"id":1,"name":"Foo","email":"foo@example.org"},{"id":2,"name":"Bar","email":"bar@example.org"}]',
      UserResource.new(users, with_traits: :name_and_email).serialize
    )
    assert_equal(
      '[{"id":1,"name":"Foo","email":"foo@example.org"},{"id":2,"name":"Bar","email":"bar@example.org"}]',
      UserResource.new(users, with_traits: [:name_and_email]).serialize
    )
  end

  class UserResource2 < UserResource
    trait :another_trait do
      attribute :special_attribute do
        42
      end
    end
  end

  def test_it_returns_multiple_traits_including_inherited
    assert_equal(
      '{"id":1,"name":"Masafumi OKURA","email":"masafumi@example.com","special_attribute":42}',
      UserResource2.new(@user, with_traits: [:name_and_email, :another_trait]).serialize
    )
    assert_equal(
      '{"id":1,"special_attribute":42}',
      UserResource2.new(@user, with_traits: :another_trait).serialize
    )
  end

  def test_it_raises_error_if_trait_not_found
    assert_raises(Alba::Error, 'Trait not found: not_found') do
      UserResource.new(@user, with_traits: :not_found).serialize
    end
  end

  class UserResourceWithProfile < UserResource
    trait :with_profile do
      one :profile, resource: ProfileResource, with_traits: :with_status
    end
  end

  def test_it_works_with_association_with_traits
    assert_equal(
      '{"id":1,"profile":{"bio":"Software Engineer at Example Corp","status":"active"}}',
      UserResourceWithProfile.new(@user, with_traits: :with_profile).serialize
    )
  end
end
