require_relative '../test_helper'

class ParamsTest < MiniTest::Test
  class User
    attr_accessor :id, :name, :email, :created_at, :updated_at, :profile, :articles

    def initialize(id, name, email)
      @id = id
      @name = name
      @email = email
      @created_at = Time.now
      @updated_at = Time.now
      @articles = []
    end
  end

  class Article
    attr_accessor :id, :title, :body

    def initialize(id, title, body)
      @id = id
      @title = title
      @body = body
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

  class UserResource
    include Alba::Resource
    root_key :user

    attributes :id, :name

    attribute :logging_in do |user|
      user.id == params[:current_user_id]
    end
  end

  class ArticleResource
    include Alba::Resource

    attributes :title
  end

  class ProfileResource
    include Alba::Resource

    attributes :email

    attribute :full_name do |profile|
      if params[:profile_full_name_with_comma]
        "#{profile.first_name}, #{profile.last_name}"
      else
        "#{profile.first_name} #{profile.last_name}"
      end
    end
  end

  class UserResource2
    include Alba::Resource
    root_key :user

    attributes :id

    one :profile, resource: ProfileResource
    many :articles,
         proc { |articles, params| articles.select { |a| params[:article_ids].include?(a.id) } },
         resource: ArticleResource
  end

  def setup
    Alba.backend = nil

    @user = User.new(1, 'Masafumi OKURA', 'masafumi@example.com')
    profile = Profile.new(1, 'test@example.com', 'Masafumi', 'Okura')
    @user.profile = profile
    article = Article.new(1, 'Hello World!', 'Hello World!!!')
    @user.articles << article
  end

  def test_params_is_empty_hash_when_given_none
    assert_equal(
      '{"user":{"id":1,"name":"Masafumi OKURA","logging_in":false}}',
      UserResource.new(@user).serialize
    )
  end

  def test_params_works_in_attribute
    assert_equal(
      '{"user":{"id":1,"name":"Masafumi OKURA","logging_in":true}}',
      UserResource.new(@user, params: {current_user_id: 1}).serialize
    )
  end

  def test_params_works_in_one_and_many
    assert_equal(
      '{"user":{"id":1,"profile":{"email":"test@example.com","full_name":"Masafumi, Okura"},"articles":[]}}',
      UserResource2.new(@user, params: {profile_full_name_with_comma: true, article_ids: [2]}).serialize
    )
  end

  class BazResource
    include Alba::Resource

    attributes :data
    attributes :secret, if: proc { params[:expose_secret] }
  end

  class BarResource
    include Alba::Resource

    one :baz, resource: BazResource
  end

  class FooResource
    include Alba::Resource

    root_key :foo

    one :bar, resource: BarResource
  end

  class FooResourceWithParamsOverride
    include Alba::Resource

    root_key :foo

    one :bar, resource: BarResource, params: {expose_secret: false}
  end

  Baz = Struct.new(:data, :secret)
  Bar = Struct.new(:baz)
  Foo = Struct.new(:bar)

  def test_params_goes_down_to_nested_resources
    foo = Foo.new(Bar.new(Baz.new(1, 'secret')))
    assert_equal(
      '{"foo":{"bar":{"baz":{"data":1,"secret":"secret"}}}}',
      FooResource.new(foo, params: {expose_secret: true}).serialize
    )
    assert_equal(
      '{"foo":{"bar":{"baz":{"data":1}}}}',
      FooResourceWithParamsOverride.new(foo, params: {expose_secret: true}).serialize
    )
  end

  class AnotherUserResource
    include Alba::Resource

    root_key :user

    attributes :id, if: proc { !params[:exclude]&.include?(:id) }
    attributes :name, :email
  end

  def test_params_filters_group_of_attributes
    user = User.new(1, 'Masafumi OKURA', 'test@example.org')
    assert_equal(
      '{"user":{"name":"Masafumi OKURA","email":"test@example.org"}}',
      AnotherUserResource.new(user, params: {exclude: [:id]}).serialize
    )
    assert_equal(
      '{"user":{"id":1,"name":"Masafumi OKURA","email":"test@example.org"}}',
      AnotherUserResource.new(user).serialize
    )
  end

  class UserResourceWithNestedAttribute
    include Alba::Resource

    root_key :user

    nested :timestamps do
      attribute :created_at do |user|
        user.created_at.getlocal(params[:timezone_offset]).strftime('%H:%M')
      end

      attribute :updated_at do |user|
        user.updated_at.getlocal(params[:timezone_offset]).strftime('%H:%M')
      end
    end
  end

  def test_params_goes_down_to_nested_attributes
    user = User.new(1, 'Masafumi OKURA', 'test@example.org')

    user_created_at_in_tz = user.created_at.getlocal('-18:00').strftime('%H:%M')
    user_updated_at_in_tz = user.updated_at.getlocal('-18:00').strftime('%H:%M')

    assert_equal(
      "{\"user\":{\"timestamps\":{\"created_at\":\"#{user_created_at_in_tz}\",\"updated_at\":\"#{user_updated_at_in_tz}\"}}}",
      UserResourceWithNestedAttribute.new(user, params: {timezone_offset: '-18:00'}).serialize
    )
  end
end
