require_relative '../test_helper'

class InheritanceAndIgnoranceTest < MiniTest::Test
  class Foo
    attr_accessor :id, :name, :body

    def initialize(id, name, body)
      @id = id
      @name = name
      @body = body
    end
  end

  class GenericFooResource
    include Alba::Resource

    attributes :id, :name, :body
  end

  class RestrictedFooResouce < GenericFooResource
    def attributes
      super.select { |key, _| key.to_sym == :name }
    end
  end

  def test_it_ignores_attributes
    foo = Foo.new(1, 'my foo', 'my body')
    assert_equal '{"name":"my foo"}', RestrictedFooResouce.new(foo).serialize
  end

  if Alba::VERSION <= '2.0'
    def test_using_ignoring_prints_warning
      assert_output('', /`ignoring` is deprecated now. Instead please use `attributes` instance method to filter out attributes./) do
        Class.new(GenericFooResource) do
          ignoring :id
        end
      end
    end
  end
end
