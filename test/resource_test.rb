# frozen_string_literal: true

require_relative 'test_helper'

class ResourceTest < Minitest::Test
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
  BarSerializer = BarResource

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
      {'foo' => {'id' => 1, 'bar_size' => 1, 'bars' => [{'id' => 1}]}}, # rubocop:disable Style/StringHashKeys
      FooResource.new(@foo).as_json
    )

    Alba.symbolize_keys!
    assert_equal(
      {foo: {id: 1, bar_size: 1, bars: [{id: 1}]}},
      FooResource.new(@foo).as_json
    )
    Alba.stringify_keys!
  end

  def test_to_json
    assert_equal(
      '{"foo":{"id":1,"bar_size":1,"bars":[{"id":1}]}}',
      FooResource.new(@foo).to_json
    )
  end

  def test_to_json_with_various_arguments # rubocop:disable Minitest/MultipleAssertions
    result = nil
    execute = -> { FooResource.new(@foo).to_json({only: :id}, root_key: :bar) }
    assert_output('', "You passed \"only\" options but ignored. Please refer to the document: https://github.com/okuramasafumi/alba/blob/main/docs/rails.md\n") { result = execute.call }
    assert_equal(
      '{"bar":{"id":1,"bar_size":1,"bars":[{"id":1}]}}',
      result
    )

    execute2 = lambda do
      FooResource.new(@foo).to_json(
        {
          only: :id,
          include: :bar,
          methods: [:baz],
          except: :excepted,
          root: :fooo
        },
        meta: {this: :meta}
      )
    end
    assert_output('', "You passed \"except\" and \"only\" options but ignored. Please refer to the document: https://github.com/okuramasafumi/alba/blob/main/docs/rails.md\n") { result = execute2.call }
    assert_equal(
      '{"foo":{"id":1,"bar_size":1,"bars":[{"id":1}]},"meta":{"this":"meta"}}',
      result
    )

    execute3 = lambda do
      FooResource.new(@foo).to_json(
        {
          layout: 'default',
          prefixes: 'prefixes',
          template: 'template',
          status: 200
        }
      )
    end
    assert_silent { result = execute3.call }
    assert_equal(
      '{"foo":{"id":1,"bar_size":1,"bars":[{"id":1}]}}',
      result
    )
  end

  def test_serializable_hash
    assert_equal(
      {'id' => 1, 'bar_size' => 1, 'bars' => [{'id' => 1}]}, # rubocop:disable Style/StringHashKeys
      FooResource.new(@foo).serializable_hash
    )
  end

  class FooSerializer
    include Alba::Serializer
    root_key :foo
    attributes :id, :bar_size
    has_many :bars, serializer: BarSerializer

    def bar_size(foo)
      foo.bars.size
    end
  end

  def test_include_serializer
    assert_equal(
      '{"foo":{"id":1,"bar_size":1,"bars":[{"id":1}]}}',
      FooSerializer.new(@foo).to_json
    )
  end

  class DeprecatedConverterResource
    include Alba::Resource
    attributes :id

    private

    def converter
      ->(o) { o }
    end
  end

  def test_deprecated_converter
    assert_equal @foo, DeprecatedConverterResource.new(@foo).as_json
  end

  class DeprecatedConverterCollectionResource
    include Alba::Resource
    attributes :id

    private

    def collection_converter
      lambda do |obj, a|
        a << obj
      end
    end
  end

  def test_deprecated_collection_converter
    assert_equal [@foo], DeprecatedConverterCollectionResource.new([@foo]).as_json
  end

  def test_deprecated_attributes
    assert_output('', /Overriding `attributes` is deprecated, use `select` instead./) do
      Class.new do
        include Alba::Resource
        attributes :id

        private

        def attributes # rubocop:disable Lint/UselessMethodDefinition
          super
        end
      end
    end
  end
end
