# frozen_string_literal: true

require 'test_helper'
require 'json'
require 'pbt'

class PbtTypeValidationTest < Minitest::Test
  Record = Struct.new(:id, :age, :bio, :admin, keyword_init: true)

  class ConvertingResource
    include Alba::Resource

    attributes id: [String, true],
               age: [Integer, true],
               admin: [:Boolean, true]
  end

  class StrictResource
    include Alba::Resource

    attributes id: String,
               age: Integer,
               bio: String,
               admin: :Boolean
  end

  def test_typed_attributes_convert_values_when_auto_conversion_is_enabled
    Pbt.assert(worker: :none) do
      Pbt.property(convertible_record_arbitrary) do |data|
        record = converting_record_from(data)

        assert_equal(
          {
            id: record.id.to_s,
            age: Integer(record.age),
            admin: !!record.admin
          },
          JSON.parse(ConvertingResource.new(record).serialize, symbolize_names: true)
        )
      end
    end
  end

  def test_typed_attributes_preserve_valid_strict_values
    Pbt.assert(worker: :none) do
      Pbt.property(strict_record_arbitrary) do |data|
        record = strict_record_from(data)

        assert_equal(
          {
            id: record.id,
            age: record.age,
            bio: record.bio,
            admin: record.admin
          },
          JSON.parse(StrictResource.new(record).serialize, symbolize_names: true)
        )
      end
    end
  end

  def test_typed_attributes_raise_for_invalid_strict_values
    Pbt.assert(worker: :none) do
      Pbt.property(invalid_strict_record_arbitrary) do |data|
        record = strict_record_from(data)

        assert_raises(TypeError) { StrictResource.new(record).serialize }
      end
    end
  end

  private

  def converting_record_from(data)
    Record.new(
      id: string_or_integer_from(data.fetch(:id)),
      age: data.fetch(:age).to_s,
      admin: boolean_like_from(data.fetch(:admin))
    )
  end

  def strict_record_from(data)
    Record.new(
      id: data.fetch(:id),
      age: data.fetch(:age),
      bio: data.fetch(:bio),
      admin: data.fetch(:admin)
    )
  end

  def convertible_record_arbitrary
    Pbt.fixed_hash(
      id: string_or_integer_arbitrary,
      age: Pbt.integer(min: -100, max: 100),
      admin: boolean_like_arbitrary
    )
  end

  def strict_record_arbitrary
    Pbt.fixed_hash(
      id: Pbt.ascii_string,
      age: Pbt.integer(min: -100, max: 100),
      bio: Pbt.ascii_string,
      admin: Pbt.boolean
    )
  end

  def invalid_strict_record_arbitrary
    Pbt.fixed_hash(
      id: Pbt.integer(min: -100, max: 100),
      age: Pbt.ascii_string,
      bio: Pbt.constant(nil),
      admin: Pbt.integer(min: -100, max: 100)
    )
  end

  def string_or_integer_arbitrary
    Pbt.fixed_hash(
      type: Pbt.choose(0..1),
      string: Pbt.ascii_string,
      integer: Pbt.integer(min: -100, max: 100)
    )
  end

  def string_or_integer_from(data)
    data.fetch(:type).zero? ? data.fetch(:string) : data.fetch(:integer)
  end

  def boolean_like_arbitrary
    Pbt.fixed_hash(
      type: Pbt.choose(0..3),
      boolean: Pbt.boolean,
      integer: Pbt.integer(min: -100, max: 100),
      string: Pbt.ascii_string
    )
  end

  def boolean_like_from(data)
    case data.fetch(:type)
    when 0 then data.fetch(:boolean)
    when 1 then data.fetch(:integer)
    when 2 then data.fetch(:string)
    when 3 then nil
    else raise ArgumentError, "unknown boolean-like type: #{data.fetch(:type)}"
    end
  end
end
