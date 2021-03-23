require_relative '../test_helper'

class CacheTest < MiniTest::Test
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

    attribute :name_with_email do |resource|
      "#{resource.name}: #{resource.email}"
    end
  end

  def setup
    require 'active_support'
    Alba.cache_store = :memory
  end

  def test_it_works_correctly_with_object_update_at_change
    user = User.new(1, 'Test', 'test@example.org')
    before_update_result = UserResource.new(user).serialize
    user.email = 'test@example.com'
    user.updated_at = Time.now
    after_update_result = UserResource.new(user).serialize
    refute_equal before_update_result, after_update_result
  end

  def test_it_works_correctly_with_object_without_update_at_change
    user = User.new(1, 'Test', 'test@example.org')
    before_update_result = UserResource.new(user).serialize
    user.email = 'test@example.com'
    after_update_result = UserResource.new(user).serialize
    refute_equal before_update_result, after_update_result
  end

  def test_it_works_correctly_with_collection_add
    users = []
    user = User.new(1, 'Test', 'test@example.org')
    users << user
    before_update_result = UserResource.new(users).serialize
    user2 = User.new(2, 'Test2', 'test2@example.org')
    users << user2
    after_update_result = UserResource.new(users).serialize
    refute_equal before_update_result, after_update_result
  end

  def test_it_works_correctly_with_collection_remove
    users = []
    user = User.new(1, 'Test', 'test@example.org')
    user2 = User.new(2, 'Test2', 'test2@example.org')
    users << user
    users << user2
    before_update_result = UserResource.new(users).serialize
    users.delete_at(0)
    after_update_result = UserResource.new(users).serialize
    refute_equal before_update_result, after_update_result
  end

  def test_without_cache
    Alba.without_cache do
      assert_equal Alba::NullCacheStore, Alba.cache.class
    end
    assert_equal ActiveSupport::Cache::MemoryStore, Alba.cache.class
  end

  def teardown
    Alba.cache_store = nil
  end
end
