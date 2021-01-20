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

  def test_array
    assert_equal(
      '{"users":[{"id":1,"articles":[{"title":"Hello World!"}]},{"id":2,"articles":[{"title":"Super nice"}]}]}',
      UserResource.new([@user1, @user2]).serialize(with: proc { set key: :users })
    )
  end

  def test_array_no_with_arg
    assert_equal(
      '[{"id":1,"articles":[{"title":"Hello World!"}]},{"id":2,"articles":[{"title":"Super nice"}]}]',
      UserResource.new([@user1, @user2]).serialize
    )
  end
end
