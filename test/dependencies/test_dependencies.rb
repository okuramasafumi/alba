require_relative '../test_helper'

class DependenciesTest < MiniTest::Test
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
  end

  def teardown
    Alba.disable_inference!
    Alba.backend = nil
  end

  if ENV['BUNDLE_GEMFILE'] == File.expand_path('gemfiles/without_active_support.gemfile')
    def test_load_error_for_inference
      assert_raises(Alba::Error) { Alba.enable_inference! }
    end

    def test_alba_error_is_raised_if_keys_should_be_transformed_but_active_support_is_no_dependency
      err = assert_raises(Alba::Error) {
        UserResourceCamel.new(@user).serialize
      }
      assert_equal("To use transform_keys, please install `ActiveSupport` gem.", err.message)      
    end

    def test_it_warns_when_set_backend_as_active_support_but_active_support_is_not_available
      assert_output('', "`ActiveSupport` is not installed, falling back to default JSON encoder.\n") { Alba.backend = :active_support }
    end
  elsif ENV['BUNDLE_GEMFILE'] == File.expand_path('gemfiles/without_oj.gemfile')
    def test_it_warns_when_set_backend_as_oj_but_oj_is_not_available
      assert_output('', "`Oj` is not installed, falling back to default JSON encoder.\n") { Alba.backend = :oj }
    end
  end
end
