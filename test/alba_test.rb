require 'test_helper'

class AlbaTest < Minitest::Test
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
    Alba.backend = nil

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
      Alba.serialize(@user, key: :foo) do
        attributes :id
        many :articles do
          attributes :title, :body
        end
      end
    )
  end

  def test_it_serializes_object_with_fully_inlined_definitions
    assert_equal(
      '{"foo":{"id":1,"articles":[{"title":"Hello World!","body":"Hello World!!!"},{"title":"Super nice","body":"Really nice!"}]}}',
      Alba.serialize(@user, key: :foo) do
        attributes :id
        many :articles do
          attributes :title, :body
        end
      end
    )
  end

  def test_it_serializes_object_with_fully_inlined_definitions_with_json
    Alba.backend = :json

    assert_equal(
      '{"foo":{"id":1,"articles":[{"title":"Hello World!","body":"Hello World!!!"},{"title":"Super nice","body":"Really nice!"}]}}',
      Alba.serialize(@user, key: :foo) do
        attributes :id
        many :articles do
          attributes :title, :body
        end
      end
    )
  end

  # oj doesn't work on Windows or JRuby
  if ENV['OS'] != 'Windows_NT' || RUBY_PLATFORM !~ /java/
    def test_it_serializes_object_with_fully_inlined_definitions_with_oj
      Alba.backend = :oj

      assert_equal(
        '{"foo":{"id":1,"articles":[{"title":"Hello World!","body":"Hello World!!!"},{"title":"Super nice","body":"Really nice!"}]}}',
        Alba.serialize(@user, key: :foo) do
          attributes :id
          many :articles do
            attributes :title, :body
          end
        end
      )
    end
  end

  def test_it_serializes_object_with_fully_inlined_definitions_with_active_support
    Alba.backend = :active_support

    assert_equal(
      '{"foo":{"id":1,"articles":[{"title":"Hello World!","body":"Hello World!!!"},{"title":"Super nice","body":"Really nice!"}]}}',
      Alba.serialize(@user, key: :foo) do
        attributes :id
        many :articles do
          attributes :title, :body
        end
      end
    )
  end

  def test_it_raises_error_with_unsupported_backend
    assert_raises(Alba::UnsupportedBackend, 'Unsupported backend, not_supported') do
      Alba.backend = :not_supported
    end
  end
end
