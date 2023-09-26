require_relative '../test_helper'

class CustomTypeTest < Minitest::Test
  Alba.register_type :iso8601, converter: ->(time) { time.iso8601(3) }, auto_convert: true
  Alba.register_type :iso8601_no_auto, converter: ->(time) { time.iso8601(3) }
  Alba.register_type :less_than_three, check: ->(obj) { obj.is_a?(Integer) && obj < 3 }

  User = Struct.new(:id, :created_at)

  def setup
    @t = Time.now
    @user = User.new(1, @t)
  end

  class UserResource
    include Alba::Resource

    attributes :id, created_at: :iso8601
  end

  def test_custom_type_with_auto_convert
    assert_equal(
      %({"id":1,"created_at":"#{@t.iso8601(3)}"}),
      UserResource.new(@user).serialize
    )
  end

  class UserResource2
    include Alba::Resource

    attributes :id, created_at: :iso8601_no_auto
  end

  def test_custom_type_without_auto_convert
    assert_raises(TypeError) { UserResource2.new(@user).serialize }
  end

  class UserResource3
    include Alba::Resource

    attributes :id, created_at: [:iso8601_no_auto, true]
  end

  def test_custom_type_without_auto_convert_but_with_true
    assert_equal(
      %({"id":1,"created_at":"#{@t.iso8601(3)}"}),
      UserResource.new(@user).serialize
    )
  end

  class UserResource4
    include Alba::Resource

    attributes id: :less_than_three
  end

  def test_custom_type_check_only
    t = Time.now
    user = User.new(4, t)
    assert_raises(TypeError) { UserResource4.new(user).serialize }
    assert_equal(
      %({"id":1}),
      UserResource4.new(@user).serialize
    )
  end

  Alba.reset!
end
