# frozen_string_literal: true

require_relative '../test_helper'

class ObjectMethodAndResourceMethodTest < Minitest::Test
  class Foo
    attr_reader :id

    def initialize(id)
      @id = id
    end

    # There's `Kernel#test` method but this one should be called
    def test
      'test'
    end

    # `params` is an existing method on `Alba::Resource` but this one should be called
    def params
      'params'
    end
  end

  # Dummy class which causes Alba to fallback
  Bar = Struct.new(:name)

  def setup
    @foo = Foo.new(1)
    @bar = Bar.new('dummy')
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
    assert_equal '{"id":42}', FooResource.new(@bar).serialize
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
    assert_equal '{"id":42}', FooResource2.new(@bar).serialize
  end

  class FooResource3
    include Alba::Resource

    attributes :id

    def id(_)
      42
    end
  end

  def test_default_behavior
    assert_equal '{"id":42}', FooResource3.new(@foo).serialize
    assert_equal '{"id":42}', FooResource3.new(@bar).serialize
  end

  class FooResource4
    include Alba::Resource

    prefer_resource_method!

    attributes :id
  end

  def test_prefer_resource_method_but_it_is_not_there
    assert_equal '{"id":1}', FooResource4.new(@foo).serialize
    assert_raises(NoMethodError) { FooResource4.new(@bar).serialize }
  end

  class FooResource5
    include Alba::Resource

    attributes :id, :test # Kernel#test should not be called
  end

  def test_kernel_method_not_called
    assert_equal '{"id":1,"test":"test"}', FooResource5.new(@foo).serialize
    assert_raises(NoMethodError) { FooResource5.new(@bar).serialize }
  end

  class FooResource6
    include Alba::Resource

    attributes :id, :params
  end

  def test_params_not_overridden
    assert_equal '{"id":1,"params":"params"}', FooResource6.new(@foo).serialize
    assert_raises(NoMethodError) { FooResource6.new(@bar).serialize }
  end

  class FooResource7 < FooResource
    include Alba::Resource

    attributes :test
  end

  def test_inheritance_works_with_resource_method
    assert_equal '{"id":42,"test":"test"}', FooResource7.new(@foo).serialize
    assert_raises(ArgumentError) { FooResource7.new(@bar).serialize } # `Kernel#test` is called
  end

  class FooResource8 < FooResource
    include Alba::Resource

    attributes :test

    def test(_)
      'overridden'
    end
  end

  def test_new_method_defined_in_inherited_class_works
    assert_equal '{"id":42,"test":"overridden"}', FooResource8.new(@foo).serialize
    assert_equal '{"id":42,"test":"overridden"}', FooResource8.new(@bar).serialize
  end
end
