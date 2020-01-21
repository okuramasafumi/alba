require 'test_helper'

class AlbaTest < Minitest::Test
  def setup
    Alba.backend = nil
  end

  def test_that_it_has_a_version_number
    refute_nil ::Alba::VERSION
  end

  def test_backend_returns_backend_if_set
    Alba.backend = :oj
    assert_equal :oj, Alba.backend
  end

  def test_it_serializes_a_hash
    hash = {foo: 42}
    assert_equal '{"foo":42}', Alba.serialize(hash)
  end

  def test_it_serializes_a_hash_with_oj_backend
    hash = {foo: 42}
    Alba.backend = :oj
    assert_equal '{"foo":42}', Alba.serialize(hash)
  end
end
