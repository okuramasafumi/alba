require_relative '../test_helper'

class DependenciesTest < MiniTest::Test
  if ENV['BUNDLE_GEMFILE'] == File.expand_path('gemfiles/without_active_support.gemfile')
    def test_load_error_for_inference
      assert_raises(Alba::Error) { Alba.enable_inference! }
    end

    def test_load_error_for_key_transformer
      assert_raises(Alba::Error) { require 'alba/key_transformer' }
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
