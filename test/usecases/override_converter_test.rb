require_relative '../test_helper'

class OverrideConverterTest < MiniTest::Test
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

  # rubocop:disable Style/MissingElse
  if RUBY_VERSION >= '2.6'
    class UserResource
      include Alba::Resource

      attributes :id, :name, :email

      private

      def converter
        super >> proc { |hash| hash.compact }
      end
    end

    def setup
      Alba.backend = nil

      @user = User.new(1, nil, nil)
    end

    def test_it_filters_nil_attributes_with_overriding_converter
      assert_equal(
        '{"id":1}',
        UserResource.new(@user).serialize
      )
    end
  end
  # rubocop:enable Style/MissingElse
end
