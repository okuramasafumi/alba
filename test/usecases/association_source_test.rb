# frozen_string_literal: true

require_relative '../test_helper'

class AssociationSourceTest < Minitest::Test
  class User
    attr_accessor :id, :name, :profile, :articles, :metadata

    def initialize(id, name)
      @id = id
      @name = name
      @articles = []
      @metadata = {}
    end

    def custom_profile_data
      {email: "#{name.downcase}@example.com", bio: "Bio for #{name}"}
    end

    def filtered_articles(status = nil)
      return @articles unless status

      @articles.select { |article| article.status == status }
    end
  end

  class Profile
    attr_accessor :id, :email, :bio

    def initialize(id, email, bio)
      @id = id
      @email = email
      @bio = bio
    end
  end

  class Article
    attr_accessor :id, :title, :status

    def initialize(id, title, status = 'published')
      @id = id
      @title = title
      @status = status
    end
  end

  class ProfileResource
    include Alba::Resource

    attributes :email, :bio
  end

  class ArticleResource
    include Alba::Resource

    attributes :id, :title, :status
  end

  def setup
    @user = User.new(1, 'John')
    @user.profile = Profile.new(1, 'john@example.com', 'Software developer')
    @user.articles << Article.new(1, 'First Post', 'published')
    @user.articles << Article.new(2, 'Draft Post', 'draft')
    @user.articles << Article.new(3, 'Another Post', 'published')
    @user.metadata = {role: 'admin', department: 'engineering'}
  end

  # Test basic source functionality with one association
  class UserResourceWithSourceOne
    include Alba::Resource

    attributes :id, :name

    one :custom_profile,
        source: proc { custom_profile_data },
        resource: ProfileResource
  end

  def test_one_association_with_basic_source
    expected = '{"id":1,"name":"John","custom_profile":{"email":"john@example.com","bio":"Bio for John"}}'
    assert_equal expected, UserResourceWithSourceOne.new(@user).serialize
  end

  # Test source with params access
  class UserResourceWithSourceAndParams
    include Alba::Resource

    attributes :id, :name

    many :filtered_articles,
         source: proc { |params| filtered_articles(params[:status]) },
         resource: ArticleResource
  end

  def test_many_association_with_source_using_params
    expected = '{"id":1,"name":"John","filtered_articles":[{"id":1,"title":"First Post","status":"published"},{"id":3,"title":"Another Post","status":"published"}]}' # rubocop: disable Layout/LineLength
    result = UserResourceWithSourceAndParams.new(@user, params: {status: 'published'}).serialize
    assert_equal expected, result
  end

  def test_many_association_with_source_using_params_returns_all_when_no_status
    expected = '{"id":1,"name":"John","filtered_articles":[{"id":1,"title":"First Post","status":"published"},{"id":2,"title":"Draft Post","status":"draft"},{"id":3,"title":"Another Post","status":"published"}]}' # rubocop: disable Layout/LineLength
    result = UserResourceWithSourceAndParams.new(@user, params: {}).serialize
    assert_equal expected, result
  end

  # Test source with custom key
  class UserResourceWithSourceAndKey
    include Alba::Resource

    attributes :id, :name

    one :profile_info,
        source: proc { custom_profile_data },
        key: :user_profile,
        resource: ProfileResource
  end

  def test_association_with_source_and_custom_key
    expected = '{"id":1,"name":"John","user_profile":{"email":"john@example.com","bio":"Bio for John"}}'
    assert_equal expected, UserResourceWithSourceAndKey.new(@user).serialize
  end

  # Test source with condition
  class UserResourceWithSourceAndCondition
    include Alba::Resource

    attributes :id, :name

    many :articles,
         proc { |articles, _params| articles.select { |a| a.status == 'published' } },
         source: proc { @articles },
         resource: ArticleResource
  end

  def test_association_with_source_and_condition
    expected = '{"id":1,"name":"John","articles":[{"id":1,"title":"First Post","status":"published"},{"id":3,"title":"Another Post","status":"published"}]}'
    assert_equal expected, UserResourceWithSourceAndCondition.new(@user).serialize
  end

  # Test source returning nil
  class UserResourceWithNilSource
    include Alba::Resource

    attributes :id, :name

    one :missing_profile,
        source: proc {},
        resource: ProfileResource
  end

  class MetadataResource
    include Alba::Resource

    attributes :role, :department
  end

  def test_association_with_source_returning_nil
    expected = '{"id":1,"name":"John","missing_profile":null}'
    assert_equal expected, UserResourceWithNilSource.new(@user).serialize
  end

  # Test source accessing instance variables
  class UserResourceWithMetadataSource
    include Alba::Resource

    attributes :id, :name

    one :metadata, source: proc { @metadata }, resource: MetadataResource
  end

  def test_association_with_source_accessing_instance_variables
    expected = '{"id":1,"name":"John","metadata":{"role":"admin","department":"engineering"}}'
    assert_equal expected, UserResourceWithMetadataSource.new(@user).serialize
  end

  # Test source with block resource definition
  class UserResourceWithSourceAndBlock
    include Alba::Resource

    attributes :id, :name

    one :profile_summary,
        source: proc { {email: custom_profile_data[:email], name: @name} } do
      attributes :email, :name
    end
  end

  def test_association_with_source_and_block_resource
    expected = '{"id":1,"name":"John","profile_summary":{"email":"john@example.com","name":"John"}}'
    assert_equal expected, UserResourceWithSourceAndBlock.new(@user).serialize
  end

  # Test error handling when source proc raises an exception
  class UserResourceWithErrorSource
    include Alba::Resource

    attributes :id, :name

    one :error_profile,
        source: proc { raise StandardError, 'Source error' },
        resource: ProfileResource
  end

  def test_association_with_source_that_raises_error
    assert_raises(StandardError) do
      UserResourceWithErrorSource.new(@user).serialize
    end
  end
end
