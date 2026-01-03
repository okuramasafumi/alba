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

    refute_predicate resource_class._attributes, :frozen?
    Alba.compile
    assert_predicate resource_class._attributes, :frozen?
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
    Class.new do
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

  # Test 9: Compile sets _compiled flag
  def test_compile_sets_compiled_flag
    resource_class = Class.new do
      include Alba::Resource

      attributes :id, :name
    end

    refute_predicate resource_class, :_compiled
    Alba.compile
    assert_predicate resource_class, :_compiled
  end

  # Test 9b: Compile generates optimized fetch_symbol_attribute method
  def test_compile_generates_optimized_method
    resource_class = Class.new do
      include Alba::Resource

      attributes :id, :name
    end

    Alba.compile

    # After compile, the class should have its own fetch_symbol_attribute method defined
    # (not inherited from InstanceMethods)
    assert resource_class.method_defined?(:fetch_symbol_attribute, false)
  end

  # Test 9c: Optimized method works correctly via fetch_symbol_attribute
  def test_optimized_method_works_correctly
    resource_class = Class.new do
      include Alba::Resource

      attributes :id, :name
    end

    Alba.compile

    user = User.new(1, 'Test')
    resource = resource_class.new(user)

    # Verify the optimized fetch_symbol_attribute returns correct values
    assert_equal 1, resource.__send__(:fetch_symbol_attribute, user, :id, :id)
    assert_equal 'Test', resource.__send__(:fetch_symbol_attribute, user, :name, :name)
  end

  # Test 10: Resources produce correct output after compile
  def test_resources_produce_correct_output_after_compile
    resource_class = Class.new do
      include Alba::Resource

      attributes :id, :name
    end

    user = User.new(42, 'Optimized')

    # Before compile
    before_compile_output = resource_class.new(user).serialize

    Alba.compile

    # After compile
    after_compile_output = resource_class.new(user).serialize

    assert_equal before_compile_output, after_compile_output
    assert_equal '{"id":42,"name":"Optimized"}', after_compile_output
  end

  # Test 11: Optimization works with resource methods
  def test_optimized_resources_with_resource_methods
    resource_class = Class.new do
      include Alba::Resource

      attributes :id, :computed

      def computed(user)
        "Hello, #{user.name}!"
      end
    end

    Alba.compile

    user = User.new(1, 'World')
    assert_equal '{"id":1,"computed":"Hello, World!"}', resource_class.new(user).serialize
  end

  # Test 12: Optimization works with Proc attributes
  def test_optimized_resources_with_proc_attributes
    resource_class = Class.new do
      include Alba::Resource

      attributes :id

      attribute :upper_name do |user|
        user.name.upcase
      end
    end

    Alba.compile

    user = User.new(1, 'test')
    assert_equal '{"id":1,"upper_name":"TEST"}', resource_class.new(user).serialize
  end

  # Test 13: Optimization works with conditional attributes
  def test_optimized_resources_with_conditional_attributes
    resource_class = Class.new do
      include Alba::Resource

      attributes :id
      attributes :name, if: proc { |user| user.id.positive? }
    end

    Alba.compile

    user = User.new(1, 'Test')
    assert_equal '{"id":1,"name":"Test"}', resource_class.new(user).serialize

    user_zero = User.new(0, 'Hidden')
    assert_equal '{"id":0}', resource_class.new(user_zero).serialize
  end

  # Test 14: Optimization works with key transformation
  def test_optimized_resources_with_key_transformation
    Alba.inflector = :active_support

    resource_class = Class.new do
      include Alba::Resource

      attributes :id, :name

      transform_keys :lower_camel
    end

    Alba.compile

    user = User.new(1, 'Test')
    assert_equal '{"id":1,"name":"Test"}', resource_class.new(user).serialize
  ensure
    Alba.inflector = nil
  end

  # Test 15: Compile works with Hash objects
  def test_optimized_resources_with_hash_objects
    resource_class = Class.new do
      include Alba::Resource

      attributes :id, :name
    end

    Alba.compile

    user_hash = {id: 1, name: 'Hash User'}
    assert_equal '{"id":1,"name":"Hash User"}', resource_class.new(user_hash).serialize
  end

  # Test 16: Optimization works with collections
  def test_optimized_resources_with_collections
    resource_class = Class.new do
      include Alba::Resource

      attributes :id, :name
    end

    Alba.compile

    users = [User.new(1, 'Alice'), User.new(2, 'Bob')]
    assert_equal '[{"id":1,"name":"Alice"},{"id":2,"name":"Bob"}]', resource_class.new(users).serialize
  end
end
