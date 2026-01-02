# frozen_string_literal: true

require_relative '../test_helper'

class CompileTest < Minitest::Test
  class User
    attr_accessor :id, :name

    def initialize(id, name)
      @id = id
      @name = name
    end
  end

  def setup
    Alba.reset!
  end

  def teardown
    Alba.reset!
  end

  # Test 1: Alba.compile freezes resource classes
  def test_compile_freezes_resource_attributes
    resource_class = Class.new do
      include Alba::Resource
      attributes :id, :name
    end

    refute resource_class._attributes.frozen?
    Alba.compile
    assert resource_class._attributes.frozen?
  end

  # Test 2: Cannot add attributes after compile
  def test_cannot_add_attributes_after_compile
    resource_class = Class.new do
      include Alba::Resource
      attributes :id
    end

    Alba.compile

    assert_raises(FrozenError) do
      resource_class.class_eval do
        attributes :name
      end
    end
  end

  # Test 3: Resources still work after compile
  def test_resources_work_after_compile
    resource_class = Class.new do
      include Alba::Resource
      attributes :id, :name
    end

    Alba.compile

    user = User.new(1, 'Test')
    assert_equal '{"id":1,"name":"Test"}', resource_class.new(user).serialize
  end

  # Test 4: Compile returns list of compiled resources
  def test_compile_returns_compiled_resources
    resource_class1 = Class.new do
      include Alba::Resource
      attributes :id
    end

    resource_class2 = Class.new do
      include Alba::Resource
      attributes :name
    end

    result = Alba.compile
    assert_includes result, resource_class1
    assert_includes result, resource_class2
  end

  # Test 5: Compile is idempotent
  def test_compile_is_idempotent
    resource_class = Class.new do
      include Alba::Resource
      attributes :id
    end

    Alba.compile
    # Second compile should not raise
    Alba.compile

    user = User.new(1, 'Test')
    assert_equal '{"id":1}', resource_class.new(user).serialize
  end

  # Test 6: Inline resources are not affected
  def test_inline_resources_work_after_compile
    resource_class = Class.new do
      include Alba::Resource
      attributes :id
    end

    Alba.compile

    user = User.new(1, 'Test')
    # Inline resources should still work
    result = Alba.serialize(user) do
      attributes :id, :name
    end
    assert_equal '{"id":1,"name":"Test"}', result
  end

  # Test 7: Resources with associations work after compile
  class Article
    attr_accessor :id, :title, :user

    def initialize(id, title, user = nil)
      @id = id
      @title = title
      @user = user
    end
  end

  def test_resources_with_associations_work_after_compile
    user_resource = Class.new do
      include Alba::Resource
      attributes :id, :name
    end

    article_resource = Class.new do
      include Alba::Resource
      attributes :id, :title
      one :user, resource: user_resource
    end

    Alba.compile

    user = User.new(1, 'Test')
    article = Article.new(1, 'Hello', user)

    expected = '{"id":1,"title":"Hello","user":{"id":1,"name":"Test"}}'
    assert_equal expected, article_resource.new(article).serialize
  end

  # Test 8: Traits work after compile
  def test_traits_work_after_compile
    resource_class = Class.new do
      include Alba::Resource
      attributes :id

      trait :detailed do
        attributes :name
      end
    end

    Alba.compile

    user = User.new(1, 'Test')
    assert_equal '{"id":1}', resource_class.new(user).serialize
    assert_equal '{"id":1,"name":"Test"}', resource_class.new(user, with_traits: [:detailed]).serialize
  end
end
