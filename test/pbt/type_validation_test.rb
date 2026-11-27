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
    Pbt.assert do
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
    Pbt.assert do
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
    Pbt.assert do
      Pbt.property(invalid_strict_record_arbitrary) do |data|
        record = strict_record_from(data)

        assert_raises(TypeError) { StrictResource.new(record).serialize }
      end
    end
  end

  private

  def converting_record_from(data)
    Record.new(
      id: data.fetch(:id),
      age: data.fetch(:age).to_s,
      admin: data.fetch(:admin)
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
      bio: Pbt.nil,
      admin: Pbt.integer(min: -100, max: 100)
    )
  end

  def string_or_integer_arbitrary
    Pbt.one_of(
      Pbt.ascii_string,
      Pbt.integer(min: -100, max: 100)
    )
  end

  def boolean_like_arbitrary
    Pbt.one_of(
      Pbt.boolean,
      Pbt.integer(min: -100, max: 100),
      Pbt.ascii_string,
      Pbt.nil
    )
  end
end
