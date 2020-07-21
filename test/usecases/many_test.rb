require_relative '../test_helper'

class ManyTest < MiniTest::Test
  class SerializerWithKey
    include Alba::Serializer

    set key: :foo
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

  class UserResource1
    include Alba::Resource

    attributes :id

    many :articles, resource: ArticleResource
  end

  def test_it_returns_correct_json_with_resource_option
    user = User.new(1)
    article1 = Article.new(1, 'Hello World!', 'Hello World!!!')
    user.articles << article1
    article2 = Article.new(2, 'Super nice', 'Really nice!')
    user.articles << article2
    assert_equal(
      '{"id":1,"articles":[{"title":"Hello World!"},{"title":"Super nice"}]}',
      UserResource1.new(user).serialize
    )
  end

  class UserResource2
    include Alba::Resource

    attributes :id

    many :articles do
      attributes :title, :body
    end
  end

  def test_it_returns_correct_json_with_block
    user = User.new(1)
    article1 = Article.new(1, 'Hello World!', 'Hello World!!!')
    user.articles << article1
    article2 = Article.new(2, 'Super nice', 'Really nice!')
    user.articles << article2
    assert_equal(
      '{"id":1,"articles":[{"title":"Hello World!","body":"Hello World!!!"},{"title":"Super nice","body":"Really nice!"}]}',
      UserResource2.new(user).serialize
    )
  end
end
