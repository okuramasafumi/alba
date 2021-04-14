require_relative '../test_helper'

class DependenciesTest < MiniTest::Test
  if ENV['BUNDLE_GEMFILE'] == File.expand_path('gemfiles/without_active_support.gemfile')
    def test_load_error_for_inference
      assert_raises(Alba::Error) { Alba.enable_inference! }
    end

    def test_load_error_for_key_transformer
      assert_raises(Alba::Error) { require 'alba/key_transformer' }
    end
  end
end
