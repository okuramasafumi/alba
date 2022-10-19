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

  def test_to_json
    # With Ruby 2 series it's difficult to define dummy options parameter
    # For Ruby 2.x we make dummy options parameter required, which should be fine for Rails
    if Gem::Version.new(RUBY_VERSION) >= Gem::Version.new('3.0')
      assert_equal(
        '{"foo":{"id":1,"bar_size":1,"bars":[{"id":1}]}}',
        FooResource.new(@foo).to_json
      )
    end
    assert_equal(
      '{"foo":{"id":1,"bar_size":1,"bars":[{"id":1}]}}',
      FooResource.new(@foo).to_json({})
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
    message = "You passed \"except\", \"include\", \"methods\", \"only\", \"root\" options but ignored. Please refer to the document: https://github.com/okuramasafumi/alba/blob/main/docs/rails.md\n"
    assert_output('', message) { result = execute2.call }
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
      {'id' => 1, 'bar_size' => 1, 'bars' => [{'id' => 1}]},
      FooResource.new(@foo).serializable_hash
    )
  end
end
