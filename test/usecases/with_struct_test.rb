require_relative '../test_helper'

class WithStructTest < Minitest::Test
  User = Struct.new(:id, :name)
  private_constant :User

  class UserResource
    include Alba::Resource

    attributes :id, :name
  end

  def test_it_works_with_struct
    user = User.new(1, 'test')
    assert_equal '{"id":1,"name":"test"}', UserResource.new(user).serialize
    user2 = User.new(2, 'test2')
    assert_equal '[{"id":1,"name":"test"},{"id":2,"name":"test2"}]', UserResource.new([user, user2]).serialize
  end
end
