# frozen_string_literal: true

require_relative '../test_helper'

class InheritanceAndIgnoranceTest < Minitest::Test
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

  class RestrictedFooResource < GenericFooResource
    def attributes
      super.select { |key, _| key.to_sym == :name }
    end
  end

  def test_it_ignores_attributes
    foo = Foo.new(1, 'my foo', 'my body')
    assert_equal '{"name":"my foo"}', RestrictedFooResource.new(foo).serialize
  end
end
