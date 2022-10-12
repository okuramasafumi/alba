require_relative '../test_helper'

class NilHandlerTest < Minitest::Test
  class User
    attr_reader :id, :name, :age
    attr_accessor :profile, :articles

    def initialize(id, name = nil, age = nil)
      @id = id
      @name = name
      @age = age
      @articles = []
    end
  end

  class Profile
    attr_accessor :user_id, :email, :first_name, :last_name

    def initialize(user_id, email, first_name = nil, last_name = nil)
      @user_id = user_id
      @email = email
      @first_name = first_name
      @last_name = last_name
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

  class ProfileResource
    include Alba::Resource

    attributes :email

    attribute :full_name do |profile|
      "#{profile.first_name} #{profile.last_name}" if profile.first_name && profile.last_name
    end
  end

  class ArticleResource
    include Alba::Resource

    attributes :title
  end

  class UserResource
    include Alba::Resource

    root_key :user, :users

    attributes :id, :name, :age

    one :profile, resource: ProfileResource
    many :articles, resource: ArticleResource
  end

  def setup
    @user1 = User.new(1, 'User1')
    article1 = Article.new(1, 'Hello World!', 'Hello World!!!')
    @user1.articles << article1
    profile1 = Profile.new(1, 'test@example.com')
    @user1.profile = profile1
    @user2 = User.new(2)
    article2 = Article.new(2, 'Super nice', 'Really nice!')
    @user2.articles << article2
    profile2 = Profile.new(2, 'test2@example.com', 'John', 'Doe')
    @user2.profile = profile2
    @user3 = User.new(3, 'User3', 19)
  end

  def teardown
    Alba.reset!
  end

  def test_without_nil_handler
    assert_equal(
      '{"user":{"id":1,"name":"User1","age":null,"profile":{"email":"test@example.com","full_name":null},"articles":[{"title":"Hello World!"}]}}',
      UserResource.new(@user1).serialize
    )
  end

  class ProfileResource1 < ProfileResource
    on_nil { '' }
  end

  class UserResource1 < UserResource
    on_nil { '' }

    one :profile, resource: ProfileResource1
  end

  def test_nil_handler_always_returning_empty_string
    assert_equal(
      '{"user":{"id":1,"name":"User1","age":"","profile":{"email":"test@example.com","full_name":""},"articles":[{"title":"Hello World!"}]}}',
      UserResource1.new(@user1).serialize
    )
    assert_equal(
      '{"user":{"id":2,"name":"","age":"","profile":{"email":"test2@example.com","full_name":"John Doe"},"articles":[{"title":"Super nice"}]}}',
      UserResource1.new(@user2).serialize
    )
    assert_equal(
      '{"user":{"id":3,"name":"User3","age":19,"profile":"","articles":[]}}',
      UserResource1.new(@user3).serialize
    )
  end

  class ProfileResource2 < ProfileResource
    on_nil do |_object, key, _attribute|
      if key == 'full_name'
        'Unknown'
      else
        ''
      end
    end
  end

  class UserResource2 < UserResource
    on_nil do |object, key, _attribute|
      case key.to_sym
      when :age
        20
      when :profile
        ProfileResource2.new(Profile.new(object.id, 'default@example.com')).serializable_hash
      else
        ''
      end
    end

    one :profile, resource: ProfileResource2
  end

  def test_nil_handler_accepting_block_arguments
    assert_equal(
      '{"user":{"id":1,"name":"User1","age":20,"profile":{"email":"test@example.com","full_name":"Unknown"},"articles":[{"title":"Hello World!"}]}}',
      UserResource2.new(@user1).serialize
    )
    assert_equal(
      '{"user":{"id":2,"name":"","age":20,"profile":{"email":"test2@example.com","full_name":"John Doe"},"articles":[{"title":"Super nice"}]}}',
      UserResource2.new(@user2).serialize
    )
    assert_equal(
      '{"user":{"id":3,"name":"User3","age":19,"profile":{"email":"default@example.com","full_name":"Unknown"},"articles":[]}}',
      UserResource2.new(@user3).serialize
    )
  end
end
