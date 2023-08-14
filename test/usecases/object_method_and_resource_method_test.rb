require_relative '../test_helper'

class ObjectMethodAndResourceMethodTest < Minitest::Test
  class Foo
    attr_reader :id

    def initialize(id)
      @id = id
    end
  end

  def setup
    @foo = Foo.new(1)
  end

  class FooResource
    include Alba::Resource

    prefer_resource_method!

    attributes :id

    def id(_)
      42
    end
  end

  def test_prefer_resource_method
    assert_equal '{"id":42}', FooResource.new(@foo).serialize
  end

  class FooResource2
    include Alba::Resource

    prefer_object_method!

    attributes :id

    def id(_)
      42
    end
  end

  def test_prefer_object_method
    assert_equal '{"id":1}', FooResource2.new(@foo).serialize
  end

  class FooResource3
    include Alba::Resource

    attributes :id

    def id(_)
      42
    end
  end

  # TODO: perfer resource method by default from version 3
  def test_default_behavior
    assert_equal '{"id":1}', FooResource3.new(@foo).serialize
  end

  class FooResource4
    include Alba::Resource

    prefer_resource_method!

    attributes :id
  end

  def test_prefer_resource_method_but_it_is_not_there
    assert_equal '{"id":1}', FooResource4.new(@foo).serialize
  end
end
