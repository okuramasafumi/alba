require_relative '../test_helper'

class SerializerMetadataTest < Minitest::Test
  class SerializerWithResourceCount
    include Alba::Serializer

    metadata(:user_count, &:count)
  end

  class SerializerWithKeyAndResourceCount < SerializerWithResourceCount
    set key: :users
  end

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

  def test_serializer_with_resource_count
    assert_equal(
      '[{"id":1,"articles":[{"title":"Hello World!"}]},{"id":2,"articles":[{"title":"Super nice"}]},{"user_count":2}]',
      UserResource.new([@user1, @user2]).serialize(with: SerializerWithResourceCount)
    )
  end

  def test_serializer_with_key_and_resource_count
    assert_equal(
      '{"users":[{"id":1,"articles":[{"title":"Hello World!"}]},{"id":2,"articles":[{"title":"Super nice"}]}],"user_count":2}',
      UserResource.new([@user1, @user2]).serialize(with: SerializerWithKeyAndResourceCount)
    )
  end
end
