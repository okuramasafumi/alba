require_relative 'test_helper'

class ResourceTest < MiniTest::Test
  class Foo
    attr_accessor :id, :bars
  end

  class Bar
    attr_accessor :id
  end

  class BarResource
    include Alba::Resource
    attributes :id
  end

  class FooResource
    include Alba::Resource
    key :foo
    attributes :id
    many :bars, resource: BarResource
  end

  def test_name_option
    assert_equal :foo, FooResource.new(Foo.new).key
    assert_equal :resourcetest_bar, BarResource.new(Foo.new).key
  end

  def test_serializable_hash
    foo = Foo.new
    foo.id = 1
    bar = Bar.new
    bar.id = 1
    foo.bars = [bar]
    assert_equal(
      {foo: {id: 1, bars: [{id: 1}]}},
      FooResource.new(foo).serializable_hash
    )
    assert_equal(
      {id: 1, bars: [{id: 1}]},
      FooResource.new(foo).serializable_hash(with_key: false)
    )
  end
end
