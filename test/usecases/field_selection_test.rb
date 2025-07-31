# frozen_string_literal: true

require_relative '../test_helper'

class FieldSelectionTest < Minitest::Test
  module FieldSelection
    def field_when_selected(*attrs, key:)
      attrs.each do |attr|
        attribute(attr, if: proc { params[:fields].nil? || params[:fields][key].include?(attr.to_sym) }) do |object|
          object.__send__(attr)
        end
      end
    end
  end

  Bar = Struct.new(:id, :name)
  Foo = Struct.new(:id, :name, :bar)

  class FooResource
    include Alba::Resource
    extend FieldSelection

    field_when_selected :id, :name, key: :foo

    one :bar do
      extend FieldSelection

      field_when_selected :id, :name, key: :bar
    end
  end

  def test_field_selection_with_params
    foo = Foo.new(1, 'foo', Bar.new(1, 'bar'))
    assert_equal(
      '{"id":1,"name":"foo","bar":{"id":1,"name":"bar"}}',
      FooResource.new(foo, params: {fields: {foo: [:id, :name], bar: [:id, :name]}}).serialize
    )
    assert_equal(
      '{"id":1,"name":"foo","bar":{"id":1}}',
      FooResource.new(foo, params: {fields: {foo: [:id, :name], bar: [:id]}}).serialize
    )
    assert_equal(
      '{"id":1,"name":"foo","bar":{"id":1,"name":"bar"}}',
      FooResource.new(foo).serialize
    )
  end
end
