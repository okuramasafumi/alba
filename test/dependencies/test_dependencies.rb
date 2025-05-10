# frozen_string_literal: true

require_relative '../test_helper'

class DependenciesTest < Minitest::Test
  class User
    attr_reader :first_name, :last_name

    def initialize(first_name, last_name)
      @first_name = first_name
      @last_name = last_name
    end
  end

  class UserResourceCamel
    include Alba::Resource

    attributes :first_name, :last_name
    transform_keys :camel
  end

  def setup
    @user = User.new('Masafumi', 'Okura')

    @original_inflector = Alba.inflector
    @original_backend = Alba.backend
  end

  def teardown
    Alba.inflector = @original_inflector
    Alba.backend = @original_backend
  end

  if ENV['BUNDLE_GEMFILE'] == File.expand_path('gemfiles/without_active_support.gemfile')
    def test_alba_error_is_raised_if_keys_should_be_transformed_but_active_support_is_no_dependency
      err = assert_raises(Alba::Error) do
        UserResourceCamel.new(@user).serialize
      end
      assert_equal('Inflector is nil. You must set inflector before transforming keys.', err.message)
    end

    def test_it_warns_when_set_backend_as_active_support_but_active_support_is_not_available
      assert_output('', "`ActiveSupport` is not installed, falling back to default JSON encoder.\n") { Alba.backend = :active_support }
    end

    class UserResourceWithRootKey
      include Alba::Resource

      root_key!

      attributes :first_name, :last_name
    end

    def test_alba_error_is_raise_if_root_key_is_set_to_true
      err = assert_raises(Alba::Error) do
        UserResourceWithRootKey.new(@user).serialize
      end
      assert_equal('You must set inflector when setting root key as true.', err.message)
    end

    def test_alba_error_is_raised_if_default_inflector_is_used
      err = assert_raises(Alba::Error) do
        Alba.inflector = :default
      end
      assert_equal('To use default inflector, please install `ActiveSupport` gem.', err.message)
    end
  elsif ENV['BUNDLE_GEMFILE'] == File.expand_path('gemfiles/without_oj.gemfile')
    def test_it_warns_when_set_backend_as_oj_but_oj_is_not_available
      assert_output('', "`Oj` is not installed, falling back to default JSON encoder.\n") { Alba.backend = :oj }
    end
  end
end
