require 'test_helper'

class AlbaTest < Minitest::Test
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

  def setup
    @user = User.new(1)
    @article1 = Article.new(1, 'Hello World!', 'Hello World!!!')
    @user.articles << @article1
    @article2 = Article.new(2, 'Super nice', 'Really nice!')
    @user.articles << @article2
  end

  def test_it_serializes_object_with_block
    assert_equal(
      '{"id":1,"articles":[{"title":"Hello World!","body":"Hello World!!!"},{"title":"Super nice","body":"Really nice!"}]}',
      Alba.serialize(@user) do
        attributes :id
        many :articles do
          attributes :title, :body
        end
      end
    )
  end

  def test_it_serializes_object_with_block_with_with_option
    assert_equal(
      '{"foo":{"id":1,"articles":[{"title":"Hello World!","body":"Hello World!!!"},{"title":"Super nice","body":"Really nice!"}]}}',
      Alba.serialize(@user, with: SerializerWithKey) do
        attributes :id
        many :articles do
          attributes :title, :body
        end
      end
    )
  end

  def test_it_serializes_object_with_block_with_invalid_with_option
    assert_raises ArgumentError do
      Alba.serialize(@user, with: :invalid_with) do
        attributes :id
        many :articles do
          attributes :title, :body
        end
      end
    end
  end

  def test_it_serializes_object_with_fully_inlined_definitions
    assert_equal(
      '{"foo":{"id":1,"articles":[{"title":"Hello World!","body":"Hello World!!!"},{"title":"Super nice","body":"Really nice!"}]}}',
      Alba.serialize(@user, with: proc { set key: :foo }) do
        attributes :id
        many :articles do
          attributes :title, :body
        end
      end
    )
  end

  def test_it_serializes_object_with_fully_inlined_definitions_with_oj
    Alba.backend = :oj

    assert_equal(
      '{"foo":{"id":1,"articles":[{"title":"Hello World!","body":"Hello World!!!"},{"title":"Super nice","body":"Really nice!"}]}}',
      Alba.serialize(@user, with: proc { set key: :foo }) do
        attributes :id
        many :articles do
          attributes :title, :body
        end
      end
    )
  end
end
