require_relative '../test_helper'

class ManyTest < MiniTest::Test
  class User
    attr_accessor :id, :created_at, :updated_at, :articles

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

  class UserResource1
    include Alba::Resource

    attributes :id

    many :articles, resource: ArticleResource
  end

  def setup
    @user = User.new(1)
    article1 = Article.new(1, 'Hello World!', 'Hello World!!!')
    @user.articles << article1
    article2 = Article.new(2, 'Super nice', 'Really nice!')
    @user.articles << article2
  end

  def test_it_returns_correct_json_with_resource_option
    assert_equal(
      '{"id":1,"articles":[{"title":"Hello World!"},{"title":"Super nice"}]}',
      UserResource1.new(@user).serialize
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
    assert_equal(
      '{"id":1,"articles":[{"title":"Hello World!","body":"Hello World!!!"},{"title":"Super nice","body":"Really nice!"}]}',
      UserResource2.new(@user).serialize
    )
  end

  class UserResource3
    include Alba::Resource

    attributes :id

    many :articles, key: 'posts', resource: ArticleResource
  end

  def test_it_returns_correct_json_with_given_key
    assert_equal(
      '{"id":1,"posts":[{"title":"Hello World!"},{"title":"Super nice"}]}',
      UserResource3.new(@user).serialize
    )
  end

  class UserResource4
    include Alba::Resource

    attributes :id

    many :articles,
         proc { |articles| articles.select { |a| a.id.even? } },
         resource: ArticleResource
  end

  def test_it_returns_correct_json_with_given_condition
    assert_equal(
      '{"id":1,"articles":[{"title":"Super nice"}]}',
      UserResource4.new(@user).serialize
    )
  end

  def test_it_returns_json_with_null_when_articles_do_not_exist_with_resource_option
    user = User.new(1)
    user.articles = nil
    assert_equal(
      '{"id":1,"articles":null}',
      UserResource1.new(user).serialize
    )
  end

  def test_it_returns_json_with_null_when_articles_do_not_exist_with_block
    user = User.new(1)
    user.articles = nil
    assert_equal(
      '{"id":1,"articles":null}',
      UserResource2.new(user).serialize
    )
  end

  class UserResource5
    include Alba::Resource

    attributes :id

    many :articles, resource: 'ManyTest::ArticleResource'
  end

  def test_it_returns_correct_json_with_resource_option_string
    assert_equal(
      '{"id":1,"articles":[{"title":"Hello World!"},{"title":"Super nice"}]}',
      UserResource5.new(@user).serialize
    )
  end

  def test_it_raises_error_when_no_resource_or_block_given_without_inference
    Alba.inflector = nil
    resource = <<~RUBY
      class UserResource6
        include Alba::Resource

        attributes :id

        many :articles
      end
    RUBY
    assert_raises(ArgumentError) { eval(resource) }
  end

  class UserResource6
    include Alba::Resource

    attributes :id

    many :articles,
         proc { |articles, _, user| articles.select { user.id == 1 } },
         resource: ArticleResource
  end

  def test_it_returns_correct_json_with_filtering_by_user_id
    assert_equal(
      '{"id":1,"articles":[{"title":"Hello World!"},{"title":"Super nice"}]}',
      UserResource6.new(@user).serialize
    )
  end

  def test_it_returns_empty_json_with_filtering_by_user_id
    user = @user.dup
    user.id = 2
    assert_equal(
      '{"id":2,"articles":[]}',
      UserResource6.new(user).serialize
    )
  end

  class UserBanned < User
    attr_reader :banned

    def initialize(id, banned)
      super(id)
      @banned = banned
    end
  end

  class ArticleWithComments < Article
    attr_accessor :comments, :show_comments

    def initialize(id, title, body, comments = [], show_comments: true)
      super(id, title, body)

      @comments = comments
      @show_comments = show_comments
    end
  end

  class Comment
    attr_accessor :id, :body

    def initialize(id, body)
      @id = id
      @body = body
    end
  end

  class CommentResource
    include Alba::Resource

    attributes :body
  end

  class ArticleWithCommentsResource
    include Alba::Resource

    attributes :id, :title

    many :comments, proc { |comments, _, article| comments.select { article.show_comments } }, resource: CommentResource
  end

  class UserResource7
    include Alba::Resource

    attributes :id

    root_key :user, :users

    many :articles, proc { |articles, _, user| articles.reject { user.banned } }, resource: ArticleWithCommentsResource
  end

  def test_it_returns_correct_json_with_nested_comments_object
    user3 = UserBanned.new(3, false)
    comments = [Comment.new(1, 'Hello Comment!')]
    article1 = ArticleWithComments.new(1, 'Hello World!', 'Hello World!!!', comments, show_comments: false)
    user3.articles << article1

    user5 = UserBanned.new(5, true)
    article2 = ArticleWithComments.new(2, 'Super nice', 'Really nice!')
    user5.articles << article2

    assert_equal(
      '{"users":[{"id":3,"articles":[{"id":1,"title":"Hello World!","comments":[]}]},{"id":5,"articles":[]}]}',
      UserResource7.new([user3, user5]).serialize
    )
  end

  class ArticleResource2
    include Alba::Resource

    attributes :id, if: proc { params.dig(:articles, :include_id) != false }
    attributes :title
  end

  class UserResource8
    include Alba::Resource

    attributes :id

    many :articles, resource: ArticleResource2
  end

  def test_it_can_select_attributes_of_association
    assert_equal(
      '{"id":1,"articles":[{"id":1,"title":"Hello World!"},{"id":2,"title":"Super nice"}]}',
      UserResource8.new(@user).serialize
    )
    assert_equal(
      '{"id":1,"articles":[{"title":"Hello World!"},{"title":"Super nice"}]}',
      UserResource8.new(@user, params: {articles: {include_id: false}}).serialize
    )
  end

  class Node
    attr_reader :id

    def initialize(id)
      @id = id
    end
  end

  class FolderNode < Node
    attr_reader :children

    def initialize(id, children = [])
      super(id)
      @children = children
    end

    def size
      children.size
    end
  end

  class FileNode < Node
    attr_reader :size

    def initialize(id, size)
      super(id)
      @size = size
    end
  end

  class FolderNodeResource
    include Alba::Resource

    attributes :id, :size

    attribute :type do
      'folder'
    end

    many :children, resource: ->(node) { node.is_a?(FolderNode) ? FolderNodeResource : FileNodeResource }
  end

  class FileNodeResource
    include Alba::Resource

    attributes :id, :size

    attribute :type do
      'file'
    end
  end

  def test_polymorphic_association_with_proc_resource
    folder = FolderNode.new(1, [FolderNode.new(2, [FileNode.new(3, 10)]), FileNode.new(4, 100)])
    assert_equal(
      '{"id":1,"size":2,"type":"folder","children":[{"id":2,"size":1,"type":"folder","children":[{"id":3,"size":10,"type":"file"}]},{"id":4,"size":100,"type":"file"}]}', # rubocop: disable Layout/LineLength
      FolderNodeResource.new(folder).serialize
    )
  end
end
