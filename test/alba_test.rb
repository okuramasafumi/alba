require 'test_helper'

class AlbaTest < Minitest::Test
  class User
    attr_reader :id, :created_at, :updated_at
    attr_accessor :profile, :articles

    def initialize(id)
      @id = id
      @created_at = Time.now
      @updated_at = Time.now
      @articles = []
    end
  end

  class Profile
    attr_reader :user_id, :email

    def initialize(user_id, email)
      @user_id = user_id
      @email = email
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
    profile = Profile.new(1, 'test@example.com')
    @user.profile = profile
    @article1 = Article.new(1, 'Hello World!', 'Hello World!!!')
    @user.articles << @article1
  end

  def teardown
    Alba.backend = nil
  end

  def test_it_serializes_object_with_block
    assert_equal(
      '{"id":1,"articles":[{"title":"Hello World!","body":"Hello World!!!"}]}',
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
      '{"foo":{"id":1,"articles":[{"title":"Hello World!","body":"Hello World!!!"}]}}',
      Alba.serialize(@user, root_key: :foo) do
        attributes :id
        many :articles do
          attributes :title, :body
        end
      end
    )
  end

  def test_it_serializes_object_with_fully_inlined_definitions
    assert_equal(
      '{"foo":{"id":1,"profile":{"email":"test@example.com"},"articles":[{"title":"Hello World!","body":"Hello World!!!"}]}}',
      Alba.serialize(@user, root_key: :foo) do
        attributes :id
        one :profile do
          attributes :email
        end
        many :articles do
          attributes :title, :body
        end
      end
    )
  end

  def test_it_serializes_object_with_fully_inlined_definitions_with_json
    Alba.backend = :json

    assert_equal(
      '{"foo":{"id":1,"articles":[{"title":"Hello World!","body":"Hello World!!!"}]}}',
      Alba.serialize(@user, root_key: :foo) do
        attributes :id
        many :articles do
          attributes :title, :body
        end
      end
    )
  end

  # oj doesn't work on Windows or JRuby
  if ENV['OS'] != 'Windows_NT' && RUBY_PLATFORM !~ /java/
    def test_it_serializes_object_with_fully_inlined_definitions_with_oj
      Alba.backend = :oj

      assert_equal(
        '{"foo":{"id":1,"articles":[{"title":"Hello World!","body":"Hello World!!!"}]}}',
        Alba.serialize(@user, root_key: :foo) do
          attributes :id
          many :articles do
            attributes :title, :body
          end
        end
      )
    end

    def test_it_works_with_oj_default_backend
      Alba.backend = :oj_default

      Oj.default_options = {mode: :object}
      assert_equal(
        '{"foo":{"id":1}}',
        Alba.serialize(@user, root_key: :foo) do
          attributes :id
        end
      )

      Oj.default_options = {mode: :compat}
      assert_equal(
        '{"foo":{"id":1}}',
        Alba.serialize(@user, root_key: :foo) do
          attributes :id
        end
      )

      Alba.symbolize_keys!
      Oj.default_options = {mode: :object}
      assert_equal(
        '{":foo":{":id":1}}',
        Alba.serialize(@user, root_key: :foo) do
          attributes :id
        end
      )
      Alba.stringify_keys!
    end
  end

  def test_it_serializes_object_with_fully_inlined_definitions_with_active_support
    Alba.backend = :active_support

    assert_equal(
      '{"foo":{"id":1,"articles":[{"title":"Hello World!","body":"Hello World!!!"}]}}',
      Alba.serialize(@user, root_key: :foo) do
        attributes :id
        many :articles do
          attributes :title, :body
        end
      end
    )
  end

  def test_it_works_with_oj_strict_backend
    Alba.backend = :oj_strict
    assert_equal(
      '{"foo":{"id":1}}',
      Alba.serialize(@user, root_key: :foo) do
        attributes :id
      end
    )
  end

  def test_it_works_with_oj_rails_backend
    Alba.backend = :oj_rails
    assert_equal(
      '{"foo":{"id":1}}',
      Alba.serialize(@user, root_key: :foo) do
        attributes :id
      end
    )
  end

  def test_it_raises_error_with_unsupported_backend
    assert_raises(Alba::UnsupportedBackend, 'Unsupported backend, not_supported') do
      Alba.backend = :not_supported
    end
  end

  def test_it_sets_encoder_directly
    Alba.encoder = ->(hash) { JSON.generate(hash) }
    assert_equal(
      '{"foo":{"id":1,"articles":[{"title":"Hello World!","body":"Hello World!!!"}]}}',
      Alba.serialize(@user, root_key: :foo) do
        attributes :id
        many :articles do
          attributes :title, :body
        end
      end
    )
    assert_equal(:custom, Alba.backend)
  end

  def test_it_raises_argument_error_when_encoder_is_not_following_spec
    assert_raises(ArgumentError, 'Encoder must be a Proc accepting one argument') do
      Alba.encoder = :does_not_work
    end
    assert_raises(ArgumentError, 'Encoder must be a Proc accepting one argument') do
      Alba.encoder = -> {}
    end
  end

  class ArticleResource
    include Alba::Resource

    attributes :title, :body
  end

  class UserResource
    include Alba::Resource

    attributes :id

    many :articles, resource: ArticleResource
  end

  def test_it_serializes_object_with_inferred_resource_when_inference_is_enabled
    Alba.inflector = :active_support
    assert_equal(
      '{"id":1,"articles":[{"title":"Hello World!","body":"Hello World!!!"}]}',
      Alba.serialize(@user)
    )
    assert_equal(
      '{"user":{"id":1,"articles":[{"title":"Hello World!","body":"Hello World!!!"}]}}',
      Alba.serialize(@user, root_key: :user)
    )
    Alba.inflector = nil
  end

  def test_it_raises_error_when_trying_to_infer_resource_when_inference_is_disabled
    Alba.inflector = nil
    assert_raises(Alba::Error) { Alba.serialize(@user) }
  end

  class Foo # rubocop:disable Lint/EmptyClass
  end

  def test_it_raises_error_when_inferred_resource_does_not_exist_even_when_infernce_is_enabled
    Alba.inflector = :active_support
    assert_raises(NameError) { Alba.serialize(Foo.new) }
    Alba.inflector = nil
  end

  # Deprecated methods

  def test_enable_inference_is_deprecated
    assert_output(nil, /Alba.enable_inference! is deprecated. Use `Alba.inflector=` instead.\n/) do
      Alba.enable_inference!(with: :active_support)
    end
  end

  def test_disable_inference_is_deprecated
    assert_output(nil, /Alba.disable_inference! is deprecated. Use `Alba.inflector = nil` instead.\n/) do
      Alba.disable_inference!
    end
  end

  def test_inferring_is_deprecated
    assert_output(nil, /Alba.inferring is deprecated. Use `Alba.inflector` instead.\n/) do
      Alba.inferring
    end
  end
end
