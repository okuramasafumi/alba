require_relative '../test_helper'

class UserDefinedSerializableHashTest < Minitest::Test
  class Foo
    attr_accessor :id, :name

    def initialize(id, name)
      @id = id
      @name = name
    end
  end

  class FooResource
    include Alba::Resource

    def serializable_hash
      grouped = object.group_by { |foo| foo.id.even? ? 'even' : 'odd' }
      grouped.transform_values { |foos| foos.map { |foo| {name: foo.name} } }
    end
  end

  def test_resource_class_with_overwriting_works
    foo1 = Foo.new(1, 'name1')
    foo2 = Foo.new(2, 'name2')
    foo3 = Foo.new(3, 'name3')
    foo4 = Foo.new(4, 'name4')
    assert_equal(
      '{"foos":{"odd":[{"name":"name1"},{"name":"name3"}],"even":[{"name":"name2"},{"name":"name4"}]}}',
      FooResource.new([foo1, foo2, foo3, foo4]).serialize(root_key: :foos)
    )
  end
end
