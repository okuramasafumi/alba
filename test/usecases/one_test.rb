# frozen_string_literal: true

require_relative '../test_helper'

class OneTest < Minitest::Test
  def teardown
    Alba.inflector = :active_support
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

    attribute :full_name do |profile|
      "#{profile.first_name} #{profile.last_name}"
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

  class UserResource3
    include Alba::Resource

    attributes :id

    one :profile, key: 'the_profile', resource: ProfileResource
  end

  def test_it_returns_correct_json_with_given_key
    user = User.new(1)
    profile = Profile.new(1, 'test@example.com', 'Masafumi', 'Okura')
    user.profile = profile
    assert_equal(
      '{"id":1,"the_profile":{"email":"test@example.com","full_name":"Masafumi Okura"}}',
      UserResource3.new(user).serialize
    )
  end

  class UserResource4
    include Alba::Resource

    attributes :id

    one :profile,
        proc { |profile, params|
          profile.email = profile.email.sub('@', params[:replace_atmark_with]) if params[:replace_atmark_with]
          profile
        },
        resource: ProfileResource
  end

  def test_it_returns_correct_json_with_given_condition
    user = User.new(1)
    profile = Profile.new(1, 'test@example.com', 'Masafumi', 'Okura')
    user.profile = profile
    assert_equal(
      '{"id":1,"profile":{"email":"test_at_example.com","full_name":"Masafumi Okura"}}',
      UserResource4.new(user, params: {replace_atmark_with: '_at_'}).serialize
    )
  end

  def test_it_returns_json_with_null_when_profile_does_not_exist_with_resource_option
    user = User.new(1)
    assert_equal(
      '{"id":1,"profile":null}',
      UserResource1.new(user).serialize
    )
  end

  def test_it_returns_json_with_null_when_profile_does_not_exist_with_block
    user = User.new(1)
    assert_equal(
      '{"id":1,"profile":null}',
      UserResource2.new(user).serialize
    )
  end

  class UserResource5
    include Alba::Resource

    attributes :id

    one :profile, resource: 'OneTest::ProfileResource'
  end

  def test_it_returns_correct_json_with_resource_option_string
    user = User.new(1)
    profile = Profile.new(1, 'test@example.com', 'Masafumi', 'Okura')
    user.profile = profile
    assert_equal(
      '{"id":1,"profile":{"email":"test@example.com","full_name":"Masafumi Okura"}}',
      UserResource5.new(user).serialize
    )
  end

  def create_resource_class
    lambda do
      klass = Class.new do
        include Alba::Resource

        attributes :id

        one :profile
      end
      OneTest.const_set(:UserResource, klass)
      klass
    end
  end

  def test_it_raises_error_when_no_resource_or_block_given_without_inference
    with_inflector(nil) do
      assert_raises(ArgumentError) { create_resource_class.call }
    end
  end

  Alba.inflector = :active_support
  class UserResource7
    include Alba::Resource

    attributes :id

    one :profile
  end

  def test_it_does_not_raise_error_when_no_resource_or_block_given_with_inference
    user = User.new(1)
    profile = Profile.new(1, 'test@example.com', 'Masafumi', 'Okura')
    user.profile = profile
    assert_equal(
      '{"id":1,"profile":{"email":"test@example.com","full_name":"Masafumi Okura"}}',
      UserResource7.new(user).serialize
    )
  end

  module Foo
    module Bar
      class ProfileResource
        include Alba::Resource

        attributes :email
      end

      class UserResource
        include Alba::Resource

        attributes :id

        one :profile
      end
    end
  end

  def test_it_infers_resource_class_within_deeply_nested_namespace
    user = User.new(1)
    profile = Profile.new(1, 'test@example.com', 'Masafumi', 'Okura')
    user.profile = profile
    assert_equal(
      '{"id":1,"profile":{"email":"test@example.com"}}',
      Foo::Bar::UserResource.new(user).serialize
    )
  end

  class Soundtrack
    attr_accessor :content

    def initialize(content)
      @content = content
    end
  end

  class Movie
    attr_accessor :id, :title

    def initialize(id, title)
      @id = id
      @title = title
    end
  end

  class TvShow
    attr_accessor :id, :title

    def initialize(id, title)
      @id = id
      @title = title
    end
  end

  class MovieResource
    include Alba::Resource

    attributes :id, :title
    attribute :type do
      'movie'
    end
  end

  class TvShowResource
    include Alba::Resource

    attributes :id, :title
    attribute :type do
      'tv_show'
    end
  end

  class SoundtrackSerializer
    include Alba::Resource

    one :content, resource: ->(content) { content.is_a?(Movie) ? MovieResource : TvShowResource }
  end

  def test_polymorphic_association_with_proc_resource
    movie = Movie.new(1, 'Yojimbo')
    soundtrack = Soundtrack.new(movie)

    assert_equal(
      '{"content":{"id":1,"title":"Yojimbo","type":"movie"}}',
      SoundtrackSerializer.new(soundtrack).serialize
    )

    tv_show = TvShow.new(1, 'Evangelion')
    soundtrack = Soundtrack.new(tv_show)

    assert_equal(
      '{"content":{"id":1,"title":"Evangelion","type":"tv_show"}}',
      SoundtrackSerializer.new(soundtrack).serialize
    )
  end
end
