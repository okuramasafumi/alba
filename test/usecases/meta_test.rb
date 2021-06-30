require_relative '../test_helper'

class MetaTest < MiniTest::Test
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
end
