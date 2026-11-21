# frozen_string_literal: true

require_relative 'test_helper'
require 'open3'
require 'rbconfig'

class FreezeTest < Minitest::Test
  def test_freeze_freezes_configuration_except_default_superclass_and_key_cache
    result = in_subprocess(<<~RUBY)
      Alba.inflector = :default
      Alba.instance_variable_set(:@custom_configuration, [])
      configuration_variables = Alba.instance_variables - %i[@default_superclass @_transformed_keys @inflector]
      returned = Alba.freeze!
      puts JSON.generate([
        returned.equal?(Alba),
        Alba.frozen?,
        configuration_variables.all? { |name| Alba.instance_variable_get(name).frozen? },
        Object.frozen?,
        Alba.inflector.frozen?
      ])
    RUBY

    assert_equal [true, true, true, false, false], result
  end

  def test_freeze_leaves_custom_default_superclass_mutable
    result = in_subprocess(<<~RUBY)
      superclass = Class.new
      Alba.default_superclass = superclass
      Alba.freeze!
      superclass.define_singleton_method(:marker) { 'changed' }
      puts JSON.generate([superclass.frozen?, superclass.marker, Alba.resource_class.superclass.equal?(superclass)])
    RUBY

    assert_equal [false, 'changed', true], result
  end

  def test_freeze_leaves_default_superclass_name_unfrozen
    result = in_subprocess(<<~RUBY)
      name = +'::Object'
      Alba.default_superclass = name
      Alba.freeze!
      puts JSON.generate([name.frozen?, Alba.resource_class.superclass.equal?(Object)])
    RUBY

    assert_equal [false, true], result
  end

  def test_freeze_leaves_transformed_key_cache_lazy_and_mutable
    result = in_subprocess(<<~RUBY)
      Alba.inflector = :default
      cache = Alba.instance_variable_get(:@_transformed_keys)
      initially_empty = cache.empty?
      Alba.freeze!
      key = Alba.transform_key(:first_name, transform_type: :lower_camel)
      puts JSON.generate([
        initially_empty,
        cache.frozen?,
        key,
        Alba.transform_key(:first_name, transform_type: :lower_camel).equal?(key)
      ])
    RUBY

    assert_equal [true, false, 'firstName', true], result
  end

  def test_freeze_prevents_reset_and_configuration_changes
    result = in_subprocess(<<~RUBY)
      Alba.inflector = :default
      Alba.freeze!
      operations = [
        -> { Alba.reset! },
        -> { Alba.backend = :json },
        -> { Alba.encoder = ->(hash) { JSON.generate(hash) } },
        -> { Alba.inflector = nil },
        -> { Alba.default_superclass = String },
        -> { Alba.symbolize_keys! },
        -> { Alba.stringify_keys! },
        -> { Alba.register_type(:Custom, check: false) },
        -> { Alba.non_collection_types << String },
        -> { Alba.instance_variable_set(:@_transformed_keys, {}) }
      ]
      errors = operations.map do |operation|
        operation.call
        nil
      rescue FrozenError
        'FrozenError'
      end
      puts JSON.generate(errors)
    RUBY

    assert_equal Array.new(10, 'FrozenError'), result
  end

  def test_freeze_specializes_symbol_keys_without_changing_conversion
    result = in_subprocess(<<~RUBY)
      Alba.symbolize_keys!
      original = Alba.method(:regularize_key)
      Alba.freeze!
      keys = [nil, :some_key, 'some_key', '', :'', '名前', :名前].map { |key| Alba.regularize_key(key) }
      puts JSON.generate([
        original != Alba.method(:regularize_key),
        keys.map { |key| [key, key.class.name] }
      ])
    RUBY

    assert_equal [
      true,
      [[nil, 'NilClass'], ['some_key', 'Symbol'], ['some_key', 'Symbol'], ['', 'Symbol'], ['', 'Symbol'], ['名前', 'Symbol'], ['名前', 'Symbol']]
    ],
                 result
  end

  def test_freeze_is_idempotent
    result = in_subprocess(<<~RUBY)
      Alba.freeze!
      original = Alba.method(:regularize_key)
      puts JSON.generate([Alba.freeze!.equal?(Alba), original == Alba.method(:regularize_key)])
    RUBY

    assert_equal [true, true], result
  end

  def test_serialization_and_key_transformation_work_after_freezing
    %w[stringify symbolize].each do |mode|
      result = in_subprocess(<<~RUBY)
        Alba.inflector = :default
        Alba.#{mode}_keys!
        record_class = Struct.new(:first_name, :last_name)
        record = record_class.new('Ada', 'Lovelace')
        existing_resource = Alba.resource_class do
          attributes :first_name
        end
        warmed_key = Alba.transform_key(:first_name, transform_type: :camel)
        Alba.freeze!
        new_resource = Alba.resource_class(key_transformation: :lower_camel) do
          root_key :person_record
          attributes :first_name, :last_name
        end
        transformations = %i[camel lower_camel dash snake].map do |type|
          Alba.transform_key(:last_name, transform_type: type)
        end
        error = begin
          Alba.transform_key(:last_name, transform_type: :unknown)
        rescue Alba::Error => exception
          exception.message
        end
        puts JSON.generate([
          existing_resource.new(record).serialize,
          new_resource.new(record).serialize,
          new_resource.new(record).as_json.keys.first.class.name,
          transformations,
          Alba.transform_key(:first_name, transform_type: :camel).equal?(warmed_key),
          error
        ])
      RUBY

      assert_equal [
        '{"first_name":"Ada"}',
        '{"personRecord":{"firstName":"Ada","lastName":"Lovelace"}}',
        mode == 'symbolize' ? 'Symbol' : 'String',
        ['LastName', 'lastName', 'last-name', 'last_name'],
        true,
        'Unknown transform type: unknown'
      ],
                   result
    end
  end

  private

  # Freezing Alba is irreversible, so each scenario needs a fresh process.
  def in_subprocess(code)
    stdout, stderr, status = Open3.capture3(RbConfig.ruby, '-I', File.expand_path('../lib', __dir__), '-ralba', '-e', code)
    assert_predicate status, :success?, stderr
    JSON.parse(stdout)
  end
end
