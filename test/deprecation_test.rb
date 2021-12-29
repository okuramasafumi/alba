require_relative 'test_helper'

class DeprecationTest < MiniTest::Test
  class User
    attr_accessor :id, :name, :email

    def initialize(id, name, email)
      @id = id
      @name = name
      @email = email
    end
  end

  class UserResource
    include Alba::Resource

    attributes :id, :name

    attribute :name_with_email do |resource|
      "#{resource.name}: #{resource.email}"
    end
  end

  class UserResourceWithKeyOnly < UserResource
    root_key :user
  end

  def setup
    Alba.backend = nil

    @user = User.new(1, 'Masafumi OKURA', 'masafumi@example.com')
  end

  def test_it_prints_deprecation_warning_when_key_is_called
    assert_output('', /\[DEPRECATION\] `key` is deprecated, use `root_key` instead.\n/) do
      Class.new do
        include Alba::Resource

        key :foo
      end
    end
  end

  def test_it_prints_deprecation_warning_when_key_bang_is_called
    assert_output('', /\[DEPRECATION\] `key!` is deprecated, use `root_key!` instead.\n/) do
      Class.new do
        include Alba::Resource

        key!
      end
    end
  end

  def test_it_prints_deprecation_warning_when_key_option_is_given_to_serialize
    assert_output('', /`key` option to `serialize` method is deprecated, use `root_key` instead.\n/) { UserResource.new(@user).serialize(key: :user) }
  end

  def test_it_prints_deprecation_warning_with_to_hash
    assert_output('', /\[DEPRECATION\] `to_hash` is deprecated, use `serializable_hash` instead./) { UserResource.new(@user).to_hash }
  end
end
