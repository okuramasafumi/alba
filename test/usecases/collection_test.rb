require_relative '../test_helper'

class CollectionTest < Minitest::Test
  class User
    attr_reader :id, :created_at, :updated_at
    attr_accessor :articles

    def initialize(id)
      @id = id
      @created_at = Time.now
      @updated_at = Time.now
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

  class ArticleResource
    include Alba::Resource

    attributes :title
  end

  class UserResource
    include Alba::Resource

    attributes :id

    many :articles, resource: ArticleResource
  end

  def setup
    @user1 = User.new(1)
    article1 = Article.new(1, 'Hello World!', 'Hello World!!!')
    @user1.articles << article1
    @user2 = User.new(2)
    article2 = Article.new(2, 'Super nice', 'Really nice!')
    @user2.articles << article2
  end

  def test_array_with_key
    assert_equal(
      '{"users":[{"id":1,"articles":[{"title":"Hello World!"}]},{"id":2,"articles":[{"title":"Super nice"}]}]}',
      UserResource.new([@user1, @user2]).serialize(root_key: :users)
    )
  end

  def test_array_without_key
    assert_equal(
      '[{"id":1,"articles":[{"title":"Hello World!"}]},{"id":2,"articles":[{"title":"Super nice"}]}]',
      UserResource.new([@user1, @user2]).serialize
    )
  end

  class UserResourceWithAdditionalAttribute < UserResource
    attributes :articles_size

    def articles_size(user)
      user.articles.size
    end
  end

  def test_array_using_attribute_methods
    assert_equal(
      '[{"id":1,"articles":[{"title":"Hello World!"}],"articles_size":1},{"id":2,"articles":[{"title":"Super nice"}],"articles_size":1}]',
      UserResourceWithAdditionalAttribute.new([@user1, @user2]).serialize
    )
  end

  class HashUserResource < UserResource
    collection_key :id
  end

  def test_array_with_collection_key
    assert_equal(
      '{"1":{"id":1,"articles":[{"title":"Hello World!"}]},"2":{"id":2,"articles":[{"title":"Super nice"}]}}',
      HashUserResource.new([@user1, @user2]).serialize
    )
  end
end
