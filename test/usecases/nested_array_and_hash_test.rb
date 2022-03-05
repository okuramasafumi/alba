require_relative '../test_helper'

class HashAttributeTest < MiniTest::Test
  class Foo
    attr_reader :id, :config
    attr_accessor :bars

    def initialize(id, config)
      @id = id
      @config = config # Hash attribute
      @bars = []
    end
  end

  class Bar
    attr_reader :data

    def initialize(data)
      @data = data # Hash attribute
    end
  end

  class FooResource
    include Alba::Resource

    attributes :id, :config
  end

  class BarResource
    include Alba::Resource

    attributes :data
  end

  class ExtendedFooResource < FooResource
    many :bars, resource: BarResource

    def attributes
      @_attributes.reject { |key, _| key == :config }
    end
  end

  def test_it_works_with_hash_attribute
    foo = Foo.new(1, {some_key: :some_value})
    assert_equal('{"id":1,"config":{"some_key":"some_value"}}', FooResource.new(foo).serialize)
  end

  def test_it_works_with_many_association_with_hash
    foo = Foo.new(1, {some_key: :some_value})
    bar1 = Bar.new(key1: :value1)
    bar2 = Bar.new(key2: :value2)
    foo.bars = [bar1, bar2]
    assert_equal('{"id":1,"bars":[{"data":{"key1":"value1"}},{"data":{"key2":"value2"}}]}', ExtendedFooResource.new(foo).serialize)
  end
end
