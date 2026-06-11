# frozen_string_literal: true

require 'test_helper'
require 'json'
require 'pbt'

class PbtFilteringTest < Minitest::Test
  Record = Struct.new(:id, :name, :email, :tag, keyword_init: true)

  class NonNilResource
    include Alba::Resource

    attributes :id, :name, :email

    def select(_key, value)
      !value.nil?
    end
  end

  class AttributeAwareResource
    include Alba::Resource

    attributes :id, :name, :email

    nested :metadata do
      attributes :tag
    end

    trait :email_trait do
      attributes :email
    end

    def select(_key, value, attribute)
      attribute.is_a?(Alba::NestedAttribute) || !value.nil?
    end
  end

  def test_select_filters_nil_values_for_single_object
    Pbt.assert(worker: :none) do
      Pbt.property(record_arbitrary) do |data|
        record = record_from(data)

        assert_equal(
          expected_non_nil_hash(record),
          JSON.parse(NonNilResource.new(record).serialize, symbolize_names: true)
        )
      end
    end
  end

  def test_select_filters_nil_values_for_collection
    Pbt.assert(worker: :none) do
      Pbt.property(Pbt.array(record_arbitrary, max: 10, empty: true)) do |records_data|
        records = records_data.map { |data| record_from(data) }

        assert_equal(
          records.map { |record| expected_non_nil_hash(record) },
          JSON.parse(NonNilResource.new(records).serialize, symbolize_names: true)
        )
      end
    end
  end

  def test_select_receives_attribute_object_for_nested_attributes_and_traits
    Pbt.assert(worker: :none) do
      Pbt.property(record_arbitrary) do |data|
        record = record_from(data)

        assert_equal(
          expected_attribute_aware_hash(record),
          JSON.parse(AttributeAwareResource.new(record, with_traits: :email_trait).serialize, symbolize_names: true)
        )
      end
    end
  end

  private

  def expected_non_nil_hash(record)
    {
      id: record.id,
      name: record.name,
      email: record.email
    }.compact
  end

  def expected_attribute_aware_hash(record)
    expected_non_nil_hash(record).merge(metadata: {tag: record.tag}.compact)
  end

  def record_from(data)
    Record.new(
      id: value_from(data.fetch(:id)),
      name: value_from(data.fetch(:name)),
      email: value_from(data.fetch(:email)),
      tag: value_from(data.fetch(:tag))
    )
  end

  def record_arbitrary
    Pbt.fixed_hash(
      id: nilable_integer_arbitrary,
      name: nilable_string_arbitrary,
      email: nilable_string_arbitrary,
      tag: nilable_string_arbitrary
    )
  end

  def nilable_integer_arbitrary
    Pbt.fixed_hash(
      value: Pbt.integer(min: -100, max: 100),
      nil: Pbt.boolean
    )
  end

  def nilable_string_arbitrary
    Pbt.fixed_hash(
      value: Pbt.ascii_string,
      nil: Pbt.boolean
    )
  end

  def value_from(data)
    data.fetch(:nil) ? nil : data.fetch(:value)
  end
end
