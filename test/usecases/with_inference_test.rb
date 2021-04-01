require_relative '../test_helper'

class WithInferenceTest < Minitest::Test
  class User
    attr_reader :id
    attr_accessor :articles

    def initialize(id)
      @id = id
      @articles = []
    end
  end

  class Article
    attr_accessor :id, :title

    def initialize(id, title)
      @id = id
      @title = title
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

  class UserInferringResource
    Alba.enable_inference! # Need this here instead of initializer
    include Alba::Resource

    attributes :id

    many :articles
  end

  def setup
    Alba.enable_inference!
    @user = User.new(1)
    @user.articles << Article.new(1, 'The title')
  end

  def teardown
    Alba.disable_inference!
  end

  def test_it_infers_resource_name
    assert_equal(
      '{"id":1,"articles":[{"title":"The title"}]}',
      UserInferringResource.new(@user).serialize
    )
  end

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
