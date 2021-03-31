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
    key :user

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
    key :user

    attributes :id

    one :profile, resource: ProfileResource
    many :articles,
         proc { |articles, params| articles.select { |a| params[:article_ids].include?(a.id) } },
         resource: ArticleResource
  end

  class UserResource3 < UserResource2
    cond = lambda do |articles, params|
      params[:foo] = true
      params[:foo] ? [] : articles
    end
    many :articles,
         cond,
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

  def test_params_cannot_be_modified
    assert_raises(FrozenError) { UserResource3.new(@user).serialize }
  end
end
