require_relative 'test_helper'

class ResourceTest < MiniTest::Test
  class Foo
    attr_accessor :id
  end

  class FooResource
    include Alba::Resource
    key :foo
  end

  class BarResource
    include Alba::Resource
  end

  def test_name_option
    assert_equal 'foo', FooResource.new(Foo.new).key
    assert_equal 'resourcetest_bar', BarResource.new(Foo.new).key
  end
end
