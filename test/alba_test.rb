# frozen_string_literal: true

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
  if ENV['OS'] != 'Windows_NT' && !RUBY_PLATFORM.include?('java')
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
    with_inflector(:active_support) do
      assert_equal(
        '{"id":1,"articles":[{"title":"Hello World!","body":"Hello World!!!"}]}',
        Alba.serialize(@user)
      )
      assert_equal(
        '{"user":{"id":1,"articles":[{"title":"Hello World!","body":"Hello World!!!"}]}}',
        Alba.serialize(@user, root_key: :user)
      )
    end
  end

  def test_it_raises_error_when_trying_to_infer_resource_when_inference_is_disabled
    with_inflector(nil) do
      assert_raises(Alba::Error) { Alba.serialize(@user) }
    end
  end

  class Empty # rubocop:disable Lint/EmptyClass
  end

  def test_it_raises_error_when_inferred_resource_does_not_exist_even_when_infernce_is_enabled
    with_inflector(:active_support) do
      assert_raises(NameError) { Alba.serialize(Empty.new) }
    end
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

  def test_inline_serialization_for_multiple_root_keys
    user = @user
    profile = user.profile
    assert_equal(
      '{"key1":{"id":1,"articles":[{"title":"Hello World!","body":"Hello World!!!"}]},"key2":{"email":"test@example.com"}}',
      Alba.serialize do
        attribute :key1 do
          UserResource.new(user).to_h
        end

        attribute :key2 do
          Alba.hashify(profile) do
            attributes :email
          end
        end
      end
    )
  end

  def test_serialize_collection_with_empty_collection
    assert_equal(
      '[]',
      Alba.serialize([])
    )
    assert_equal(
      '[]',
      Alba.serialize([], with: :inference)
    )
  end

  Foo = Struct.new(:id, :name)
  Bar = Struct.new(:id, :address)

  class FooResource
    include Alba::Resource

    attributes :id, :name
  end

  class BarResource
    include Alba::Resource

    attributes :id, :address
  end

  class CustomFooResource
    include Alba::Resource

    attributes :id
  end

  def test_serialize_collection_with_same_type
    with_inflector(:active_support) do
      foo1 = Foo.new(1, 'foo1')
      foo2 = Foo.new(2, 'foo2')

      assert_equal(
        '[{"id":1,"name":"foo1"},{"id":2,"name":"foo2"}]',
        Alba.serialize([foo1, foo2])
      )
      assert_equal(
        '[{"id":1},{"id":2}]',
        Alba.serialize([foo1, foo2], with: CustomFooResource)
      )
      assert_equal(
        '{"foos":[{"id":1,"name":"foo1"}]}',
        Alba.serialize([foo1], root_key: :foos)
      )
    end
  end

  def test_serialize_collection_with_different_types
    foo1 = Foo.new(1, 'foo1')
    foo2 = Foo.new(2, 'foo2')
    bar1 = Bar.new(1, 'bar1')
    bar2 = Bar.new(2, 'bar2')

    with_inflector(:active_support) do
      assert_equal(
        '[{"id":1,"name":"foo1"},{"id":1,"address":"bar1"},{"id":2,"name":"foo2"},{"id":2,"address":"bar2"}]',
        Alba.serialize([foo1, bar1, foo2, bar2], with: :inference)
      )
      assert_equal(
        '[{"id":1},{"id":1,"address":"bar1"},{"id":2},{"id":2,"address":"bar2"}]',
        Alba.serialize(
          [foo1, bar1, foo2, bar2],
          with: lambda do |obj|
            case obj
            when Foo
              CustomFooResource
            when Bar
              BarResource
            else
              raise # Impossible in this case
            end
          end
        )
      )
    end

    with_inflector(nil) do
      assert_raises(Alba::Error) { Alba.serialize([foo1, bar1, foo2, bar2]) }
    end
  end

  # rubocop:disable Style/StringHashKeys
  def test_hashify_collection_with_different_types
    foo1 = Foo.new(1, 'foo1')
    foo2 = Foo.new(2, 'foo2')
    bar1 = Bar.new(1, 'bar1')
    bar2 = Bar.new(2, 'bar2')

    with_inflector(:active_support) do
      assert_equal(
        [{'id' => 1, 'name' => 'foo1'}, {'id' => 1, 'address' => 'bar1'}, {'id' => 2, 'name' => 'foo2'}, {'id' => 2, 'address' => 'bar2'}],
        Alba.hashify([foo1, bar1, foo2, bar2], with: :inference)
      )
      assert_equal(
        [{'id' => 1}, {'id' => 1, 'address' => 'bar1'}, {'id' => 2}, {'id' => 2, 'address' => 'bar2'}],
        Alba.hashify(
          [foo1, bar1, foo2, bar2],
          with: lambda do |obj|
            case obj
            when Foo
              CustomFooResource
            when Bar
              BarResource
            else
              raise # Impossible in this case
            end
          end
        )
      )
    end
    with_inflector(nil) do
      assert_raises(Alba::Error) { Alba.hashify([foo1, bar1, foo2, bar2]) }
    end
  end
  # rubocop:enable Style/StringHashKeys

  def test_serialize_collection_with_block
    foo1 = Foo.new(1, 'foo1')
    foo2 = Foo.new(2, 'foo2')

    assert_equal(
      '[{"id":1},{"id":2}]',
      Alba.serialize([foo1, foo2]) do
        attributes :id
      end
    )
  end

  def test_serialize_collection_with_unknown_with
    assert_raises(ArgumentError, '`with` argument must be either :inference, Proc or Class') { Alba.serialize([1, 2, 3], with: :unknown) }
  end

  def test_serialize_nil_without_block_raises_argument_error
    with_inflector(:active_support) do
      assert_raises(ArgumentError, 'Either object or block must be given') { Alba.serialize }
      assert_raises(ArgumentError, 'Either object or block must be given') { Alba.hashify }
    end
  end

  def test_transform_key_with_camel
    with_inflector(:active_support) do
      assert_equal(
        'FooBar',
        Alba.transform_key(:foo_bar, transform_type: :camel)
      )
    end
  end

  def test_transform_key_with_lower_camel
    with_inflector(:active_support) do
      assert_equal(
        'fooBar',
        Alba.transform_key('foo_bar', transform_type: :lower_camel)
      )
    end
  end

  def test_transform_key_with_dash
    with_inflector(:active_support) do
      assert_equal(
        'foo-bar',
        Alba.transform_key(:foo_bar, transform_type: :dash)
      )
    end
  end

  def test_transform_key_with_snake
    with_inflector(:active_support) do
      assert_equal(
        'foo_bar',
        Alba.transform_key('FooBar', transform_type: :snake)
      )
    end
  end

  def test_transform_key_with_unknown
    with_inflector(:active_support) do
      assert_raises(Alba::Error) do
        Alba.transform_key(:foo_bar, transform_type: :this_is_an_error)
      end
    end
  end
end
