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
    err = assert_raises(Alba::Error) do
      UserResource.new(@user, with_traits: :not_found).serialize
    end
    assert_match(/Trait not found: not_found/, err.message)
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

  class UserResourceWithInstanceMethod < UserResource
    trait :formatted_name do
      attribute :formatted_name do
        format_name
      end
    end

    private

    def format_name
      "Mr./Ms. #{object.name}"
    end
  end

  def test_it_works_with_instance_method_in_trait
    assert_equal(
      '{"id":1,"formatted_name":"Mr./Ms. Masafumi OKURA"}',
      UserResourceWithInstanceMethod.new(@user, with_traits: :formatted_name).serialize
    )
  end

  module FormatNameExtension
    def format_name
      "Mr./Ms. #{object.name}"
    end
  end

  class UserResourceWithExtension < UserResource
    include FormatNameExtension

    trait :formatted_name do
      attribute :formatted_name do
        format_name
      end
    end
  end

  def test_it_works_with_extension_in_trait
    assert_equal(
      '{"id":1,"formatted_name":"Mr./Ms. Masafumi OKURA"}',
      UserResourceWithExtension.new(@user, with_traits: :formatted_name).serialize
    )
  end

  class UserResourceWithOverride
    include Alba::Resource

    attributes :id, :name

    trait :with_uppercased_name do
      attribute :name do |user|
        user.name.upcase
      end
    end

    trait :with_greeting do
      attribute :greeting do |user|
        "Hello, #{user.name}!"
      end
    end
  end

  def test_multiple_traits_with_override_order_independent
    assert_equal(
      '{"id":1,"name":"MASAFUMI OKURA","greeting":"Hello, Masafumi OKURA!"}',
      UserResourceWithOverride.new(@user, with_traits: [:with_uppercased_name, :with_greeting]).serialize
    )
    assert_equal(
      '{"id":1,"name":"MASAFUMI OKURA","greeting":"Hello, Masafumi OKURA!"}',
      UserResourceWithOverride.new(@user, with_traits: [:with_greeting, :with_uppercased_name]).serialize
    )
  end

  def test_single_trait_with_attribute_override
    assert_equal(
      '{"id":1,"name":"MASAFUMI OKURA"}',
      UserResourceWithOverride.new(@user, with_traits: [:with_uppercased_name]).serialize
    )
  end

  def test_trait_does_not_include_base_attributes
    assert_equal(
      '{"id":1,"name":"Masafumi OKURA","greeting":"Hello, Masafumi OKURA!"}',
      UserResourceWithOverride.new(@user, with_traits: [:with_greeting]).serialize
    )
  end

  class UserWithMethodInTraitResource < UserResource
    trait :with_shouted_name do
      attributes :shouted_name

      def shouted_name(user)
        user.name.upcase
      end
    end
  end

  def test_method_defined_in_trait_is_available_during_serialization
    assert_equal(
      '{"id":1,"shouted_name":"MASAFUMI OKURA"}',
      UserWithMethodInTraitResource.new(@user, with_traits: :with_shouted_name).serialize
    )
  end

  class UserWithRootKeyResource < UserResource
    root_key!
  end

  def test_trait_with_inferred_root_key
    original_inflector = Alba.inflector
    Alba.inflector = :default
    assert_equal(
      '{"user_with_root_key":{"id":1,"name":"Masafumi OKURA","email":"masafumi@example.com"}}',
      UserWithRootKeyResource.new(@user, with_traits: :name_and_email).serialize
    )
  ensure
    Alba.inflector = original_inflector
  end

  def test_trait_is_evaluated_once_however_many_objects_are_serialized
    evaluations = 0
    resource_class = Class.new do
      include Alba::Resource

      attributes :id

      trait :counted do
        evaluations += 1
        attributes :name
      end
    end
    users = [@user, User.new(2, 'Foo', 'foo@example.com'), User.new(3, 'Bar', 'bar@example.com')]

    resource_class.new(users, with_traits: [:counted]).serialize

    assert_equal 1, evaluations
  end

  def test_trait_is_not_reevaluated_when_the_caller_mutates_the_traits_array
    evaluations = 0
    resource_class = Class.new do
      include Alba::Resource

      attributes :id

      trait :counted do
        evaluations += 1
        attributes :name
      end
    end
    traits = [:counted]

    resource_class.new(@user, with_traits: traits).serialize
    traits << :counted
    resource_class.new(@user, with_traits: [:counted]).serialize

    assert_equal 1, evaluations
  end

  class UserResourceWithSelect
    include Alba::Resource

    attributes :id

    trait :name_and_email do
      attributes :name, :email
    end

    def select(_key, value)
      !value.to_s.include?('@')
    end
  end

  def test_select_defined_on_the_resource_filters_trait_attributes
    assert_equal(
      '{"id":1,"name":"Masafumi OKURA"}',
      UserResourceWithSelect.new(@user, with_traits: :name_and_email).serialize
    )
  end

  def test_select_passed_to_new_applies_per_call_despite_the_memoized_trait_class
    resource_class = Class.new do
      include Alba::Resource

      attributes :id

      trait :with_name do
        attributes :name
      end
    end
    drop_strings = ->(_key, value) { !value.is_a?(String) }
    keep_all = ->(_key, _value) { true }

    assert_equal '{"id":1}', resource_class.new(@user, with_traits: :with_name, select: drop_strings).serialize
    assert_equal(
      '{"id":1,"name":"Masafumi OKURA"}',
      resource_class.new(@user, with_traits: :with_name, select: keep_all).serialize
    )
    assert_equal '{"id":1}', resource_class.new(@user, with_traits: :with_name, select: drop_strings).serialize
  end

  def test_traits_applied_in_a_different_order_do_not_share_their_attributes
    assert_equal(
      '{"id":1,"name":"MASAFUMI OKURA","greeting":"Hello, Masafumi OKURA!"}',
      UserResourceWithOverride.new(@user, with_traits: %i[with_greeting with_uppercased_name]).serialize
    )
    assert_equal(
      '{"id":1,"name":"MASAFUMI OKURA","greeting":"Hello, Masafumi OKURA!"}',
      UserResourceWithOverride.new(@user, with_traits: %i[with_uppercased_name with_greeting]).serialize
    )
    assert_equal(
      '{"id":1,"name":"Masafumi OKURA"}',
      UserResourceWithOverride.new(@user).serialize
    )
  end
end
