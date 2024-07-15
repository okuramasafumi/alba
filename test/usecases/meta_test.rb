# frozen_string_literal: true

require_relative '../test_helper'

class MetaTest < Minitest::Test
  class User
    attr_accessor :id, :name, :email, :created_at, :updated_at

    def initialize(id, name, email)
      @id = id
      @name = name
      @email = email
      @created_at = Time.now
      @updated_at = Time.now
    end
  end

  class UserResource
    include Alba::Resource

    attributes :id, :name

    meta do
      if object.is_a?(Enumerable)
        {size: object.size}
      else
        {foo: :bar}
      end
    end
  end

  class UserResourceWithRootKey < UserResource
    root_key :user, :users
  end

  def setup
    Alba.backend = nil

    @user = User.new(1, 'Masafumi OKURA', 'masafumi@example.com')
  end

  def test_it_does_not_include_meta_for_singluar_resource_when_root_key_is_not_defined
    assert_equal(
      '{"id":1,"name":"Masafumi OKURA"}',
      UserResource.new(@user).serialize
    )
  end

  def test_it_includes_meta_for_singluar_resource_when_root_key_is_defined
    assert_equal(
      '{"user":{"id":1,"name":"Masafumi OKURA"},"meta":{"foo":"bar"}}',
      UserResourceWithRootKey.new(@user).serialize
    )
  end

  def test_it_does_not_include_meta_for_collection_when_root_key_is_not_defined
    assert_equal(
      '[{"id":1,"name":"Masafumi OKURA"}]',
      UserResource.new([@user]).serialize
    )
  end

  def test_it_includes_meta_for_collection_when_root_key_is_defined
    assert_equal(
      '{"users":[{"id":1,"name":"Masafumi OKURA"}],"meta":{"size":1}}',
      UserResourceWithRootKey.new([@user]).serialize
    )
  end

  def test_it_merges_meta_with_given_meta_option
    assert_equal(
      '{"users":[{"id":1,"name":"Masafumi OKURA"}],"meta":{"size":1,"class":"MetaTest"}}',
      UserResourceWithRootKey.new([@user]).serialize(meta: {class: 'MetaTest'})
    )
  end

  def test_it_overrides_meta_with_given_meta_option
    assert_equal(
      '{"users":[{"id":1,"name":"Masafumi OKURA"}],"meta":{"size":2}}',
      UserResourceWithRootKey.new([@user]).serialize(meta: {size: 2})
    )
  end

  class UserResourceWithoutMeta
    include Alba::Resource

    root_key :user, :users

    attributes :id, :name
  end

  def test_it_includes_meta_with_given_meta_option_without_meta_dsl
    assert_equal(
      '{"users":[{"id":1,"name":"Masafumi OKURA"}],"meta":{"class":"MetaTest"}}',
      UserResourceWithoutMeta.new([@user]).serialize(meta: {class: 'MetaTest'})
    )
  end

  class UserResource2
    include Alba::Resource

    root_key :user, :users

    attributes :id, :name

    meta :my_meta do
      if object.is_a?(Enumerable)
        {size: object.size}
      else
        {foo: :bar}
      end
    end
  end

  def test_changing_meta_key
    assert_equal(
      '{"users":[{"id":1,"name":"Masafumi OKURA"}],"my_meta":{"size":1}}',
      UserResource2.new([@user]).serialize
    )
  end

  def test_changing_meta_key_with_meta_ooption
    assert_equal(
      '{"users":[{"id":1,"name":"Masafumi OKURA"}],"my_meta":{"size":1,"extra":42}}',
      UserResource2.new([@user]).serialize(meta: {extra: 42})
    )
  end

  def test_changing_meta_keu_and_overriding_meta
    assert_equal(
      '{"users":[{"id":1,"name":"Masafumi OKURA"}],"my_meta":{"size":42}}',
      UserResource2.new([@user]).serialize(meta: {size: 42})
    )
  end

  class UserResource3
    include Alba::Resource

    root_key :user, :users

    attributes :id, :name

    meta :my_meta # Change meta key only
  end

  def test_changing_meta_key_only
    assert_equal(
      '{"users":[{"id":1,"name":"Masafumi OKURA"}],"my_meta":{"extra":42}}',
      UserResource3.new([@user]).serialize(meta: {extra: 42})
    )
  end

  def test_changing_meta_key_and_eventually_no_meta
    assert_equal(
      '{"users":[{"id":1,"name":"Masafumi OKURA"}]}',
      UserResource3.new([@user]).serialize
    )
  end

  class UserResource4
    include Alba::Resource

    root_key :user, :users

    attributes :id, :name

    meta nil # Do not nest meta key
  end

  def test_meta_without_nesting
    assert_equal(
      '{"users":[{"id":1,"name":"Masafumi OKURA"}],"extra":42}',
      UserResource4.new([@user]).serialize(meta: {extra: 42})
    )
  end

  def test_meta_without_nesting_but_eventually_no_meta
    assert_equal(
      '{"users":[{"id":1,"name":"Masafumi OKURA"}]}',
      UserResource4.new([@user]).serialize
    )
  end
end
