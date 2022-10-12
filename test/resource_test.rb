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
    root_key :foo
    attributes :id, :bar_size
    many :bars, resource: BarResource

    def bar_size(foo)
      foo.bars.size
    end
  end

  def setup
    @foo = Foo.new
    @foo.id = 1
    @bar = Bar.new
    @bar.id = 1
    @foo.bars = [@bar]
  end

  def test_as_json
    assert_equal(
      {'foo' => {'id' => 1, 'bar_size' => 1, 'bars' => [{'id' => 1}]}},
      FooResource.new(@foo).as_json
    )
  end

  def test_serializable_hash
    assert_equal(
      {'id' => 1, 'bar_size' => 1, 'bars' => [{'id' => 1}]},
      FooResource.new(@foo).serializable_hash
    )
  end
end
