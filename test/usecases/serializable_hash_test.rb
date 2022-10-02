require_relative '../test_helper'

class SerializableHashTest < MiniTest::Test
  class MyThing
    attr_accessor :name

    def initialize(name:)
      @name = name
    end
  end

  class TestSerializer
    include Alba::Resource

    root_key :widget

    attributes :name
  end

  def test_serializable_hash_without_root_key_option_includes_root_key
    assert_equal(
      {'widget' => {name: 'joe'}},
      TestSerializer.new(MyThing.new(name: 'joe')).serializable_hash
    )
  end

  def test_serializable_hash_with_root_key_option_set_to_true_includes_root_key
    assert_equal(
      {'widget' => {name: 'joe'}},
      TestSerializer.new(MyThing.new(name: 'joe')).serializable_hash(root_key: true)
    )
  end

  def test_serializable_hash_with_root_key_option_set_to_false_does_not_include_root_key
    assert_equal(
      {name: 'joe'},
      TestSerializer.new(MyThing.new(name: 'joe')).serializable_hash(root_key: false)
    )
  end

  class TestSerializer2
    include Alba::Resource

    root_key :widget

    attributes :name

    def default_root_key
      false
    end
  end

  def test_serializable_hash_without_root_key_option_does_not_include_root_key_when_default_root_key_method_returns_false
    assert_equal(
      {name: 'joe'},
      TestSerializer2.new(MyThing.new(name: 'joe')).serializable_hash
    )
  end
end
