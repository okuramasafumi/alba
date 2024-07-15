# frozen_string_literal: true

require_relative '../test_helper'

class RootKeyCollectionTest < Minitest::Test
  class User
    attr_reader :id, :name, :created_at, :updated_at

    def initialize(id, name)
      @id = id
      @name = name
      @created_at = Time.now
      @updated_at = Time.now
    end
  end

  class UserResource
    include Alba::Resource

    root_key_for_collection :users

    attributes :id, :name
  end

  def setup
    @users = [User.new(1, 'Masafumi OKURA'), User.new(2, 'heka1024')]
  end

  def test_root_key_collection
    assert_equal(
      '{"users":[{"id":1,"name":"Masafumi OKURA"},{"id":2,"name":"heka1024"}]}',
      UserResource.new(@users).serialize
    )
  end
end
