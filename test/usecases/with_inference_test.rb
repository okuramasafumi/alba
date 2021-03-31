require_relative '../test_helper'

class WithInferenceTest < Minitest::Test
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
    attr_accessor :id, :title, :body

    def initialize(id, title, body)
      @id = id
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

    key!

    attributes :id

    many :articles, resource: ArticleResource
  end

  def setup
    Alba.with_inference!
    @user = User.new(1)
    @user.articles << Article.new(1, 'The title', 'The body')
  end

  def teardown
    Alba.without_inference!
  end

  #   def test_it_infers_resource_name
  #     assert_equal(
  #       '{"id":1,"articles":[{"title":"The title"}]}',
  #       UserResource.new(@user).serialize
  #     )
  #   end

  def test_it_infers_key_with_key_bang
    assert_equal(
      '{"user":{"id":1,"articles":[{"title":"The title"}]}}',
      UserResource.new(@user).serialize
    )
  end

  def test_it_infers_key_with_key_bang_when_object_is_collection
    users = [User.new(1), User.new(2)]
    assert_equal(
      '{"users":[{"id":1,"articles":[]},{"id":2,"articles":[]}]}',
      UserResource.new(users).serialize
    )
  end

  def test_it_prioritize_serialize_arg_with_key_bang
    assert_equal(
      '{"foo":{"id":1,"articles":[{"title":"The title"}]}}',
      UserResource.new(@user).serialize(key: :foo)
    )
  end
end
