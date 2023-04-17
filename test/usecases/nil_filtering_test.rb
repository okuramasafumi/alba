require_relative '../test_helper'

class NilFilteringTest < MiniTest::Test
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

    attributes :id, :name, :email

    def select(_k, v)
      !v.nil?
    end
  end

  def setup
    @user = User.new(1, nil, nil)
  end

  def test_it_filters_nil_attributes_with_select
    assert_equal(
      '{"id":1}',
      UserResource.new(@user).serialize
    )
  end
end
