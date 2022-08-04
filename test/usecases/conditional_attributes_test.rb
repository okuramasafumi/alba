require_relative '../test_helper'

class ConditionalAttributesTest < MiniTest::Test
  class User
    attr_accessor :id, :name, :profile, :articles

    def initialize(id, name)
      @id = id
      @name = name
      @articles = []
    end
  end

  class Article
    attr_accessor :user_id, :title, :body

    def initialize(user_id, title, body)
      @user_id = user_id
      @title = title
      @body = body
    end
  end

  class Profile
    attr_accessor :user_id, :email

    def initialize(user_id, email)
      @user_id = user_id
      @email = email
    end
  end

  class UserResource
    include Alba::Resource

    attributes :id
  end

  class ArticleResource
    include Alba::Resource

    attributes :title
  end

  class ProfileResource
    include Alba::Resource

    attributes :email
  end

  class UserResource1 < UserResource
    attributes :name, if: proc { |_user, name| name.size >= 5 }
  end

  class UserResource2 < UserResource
    attribute :username, if: proc { |user| user.id == 1 } do
      'username'
    end
  end

  class UserResource3 < UserResource
    one :profile, resource: ProfileResource, if: proc { |_user, profile| profile.email.end_with?('com') }
  end

  class UserResource4 < UserResource
    many :articles, resource: ArticleResource, if: proc { |_user, articles| !articles.empty? }
  end

  class UserResource6 < UserResource
    attributes :full_name, if: proc { |user| user.respond_to?(:full_name) }
  end

  class UserResource7 < UserResource
    attributes :name, if: proc { |_user| print 'foo' or true }
  end

  class UserResource8 < UserResource
    attributes :name, if: proc { !!params[:should_have_name] }
  end

  class UserResource9 < UserResource
    attributes :name, if: proc { |_user, _name| !!params[:should_have_name] }
  end

  def setup
    @user = User.new(1, 'Masafumi OKURA')
    profile = Profile.new(1, 'test@example.com')
    @user.profile = profile
    article = Article.new(1, 'Hello World!', 'Hello World!!!')
    @user.articles << article
  end

  def test_conditional_attributes_with_if
    assert_equal(
      '{"id":1,"name":"Masafumi OKURA"}',
      UserResource1.new(@user).serialize
    )
    user = User.new(2, 'Foo')
    assert_equal(
      '{"id":2}',
      UserResource1.new(user).serialize
    )
    assert_equal(
      '[{"id":1,"name":"Masafumi OKURA"},{"id":2}]',
      UserResource1.new([@user, user]).serialize
    )
  end

  def test_conditional_attribute_with_if
    assert_equal(
      '{"id":1,"username":"username"}',
      UserResource2.new(@user).serialize
    )
    user = User.new(2, 'Foo')
    assert_equal(
      '{"id":2}',
      UserResource2.new(user).serialize
    )
    assert_equal(
      '[{"id":1,"username":"username"},{"id":2}]',
      UserResource2.new([@user, user]).serialize
    )
  end

  def test_conditional_one_with_if
    assert_equal(
      '{"id":1,"profile":{"email":"test@example.com"}}',
      UserResource3.new(@user).serialize
    )
    user = User.new(2, 'Foo')
    profile = Profile.new(2, 'test@example.org')
    user.profile = profile
    assert_equal(
      '{"id":2}',
      UserResource3.new(user).serialize
    )
  end

  def test_conditional_many_with_if
    assert_equal(
      '{"id":1,"articles":[{"title":"Hello World!"}]}',
      UserResource4.new(@user).serialize
    )
    user = User.new(2, 'Foo')
    assert_equal(
      '{"id":2}',
      UserResource4.new(user).serialize
    )
  end

  def test_conditional_attribute_with_if_with_only_one_parameter
    assert_equal(
      '{"id":1}',
      UserResource6.new(@user).serialize
    )
  end

  def test_conditional_attribute_with_if_with_one_parameter_yields_only_once
    assert_output('foo') { UserResource7.new(@user).serialize }
  end

  def test_conditional_attributes_with_params_in_if_without_block_parameters
    assert_equal(
      '{"id":1,"name":"Masafumi OKURA"}',
      UserResource8.new(@user, params: {should_have_name: true}).serialize
    )
    assert_equal(
      '{"id":1}',
      UserResource8.new(@user, params: {should_have_name: false}).serialize
    )
    assert_equal(
      '{"id":1}',
      UserResource8.new(@user).serialize
    )
  end

  def test_conditional_attributes_with_params_in_if_with_block_parameters
    assert_equal(
      '{"id":1,"name":"Masafumi OKURA"}',
      UserResource9.new(@user, params: {should_have_name: true}).serialize
    )
    assert_equal(
      '{"id":1}',
      UserResource9.new(@user, params: {should_have_name: false}).serialize
    )
    assert_equal(
      '{"id":1}',
      UserResource9.new(@user).serialize
    )
  end

  class UserResource10 < UserResource
    attributes :name, if: :method_returning_true

    def method_returning_true
      true
    end
  end

  class UserResource11 < UserResource
    attributes :name, if: :method_returning_false

    def method_returning_false
      false
    end
  end

  def test_conditional_attributes_with_if_with_symbol_method_name
    assert_equal(
      '{"id":1,"name":"Masafumi OKURA"}',
      UserResource10.new(@user).serialize
    )
    assert_equal(
      '{"id":1}',
      UserResource11.new(@user).serialize
    )
  end
end
