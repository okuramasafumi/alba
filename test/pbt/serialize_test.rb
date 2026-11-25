# frozen_string_literal: true

require 'test_helper'
require 'json'
require 'pbt'

class PbtSerializeTest < Minitest::Test
  Record = Struct.new(:id, :name, :active, keyword_init: true)

  class RecordResource
    include Alba::Resource

    attributes :id, :name, :active
  end

  def test_serialize_outputs_expected_json_shape_for_single_object
    Pbt.assert(worker: :none) do
      Pbt.property(record_case_arbitrary) do |data|
        record = record_from(data.fetch(:record))
        root_key = data.fetch(:root_key)

        assert_equal(
          with_root_key(expected_record_hash(record), root_key),
          JSON.parse(Alba.serialize(record, with: RecordResource, root_key: root_key), symbolize_names: true)
        )
      end
    end
  end

  def test_serialize_outputs_expected_json_shape_for_collection
    Pbt.assert(worker: :none) do
      Pbt.property(collection_case_arbitrary) do |data|
        collection = data.fetch(:records).map { |record_data| record_from(record_data) }
        root_key = data.fetch(:root_key)

        assert_equal(
          with_root_key(collection.map { |record| expected_record_hash(record) }, root_key),
          JSON.parse(Alba.serialize(collection, with: RecordResource, root_key: root_key), symbolize_names: true)
        )
      end
    end
  end

  private

  def expected_record_hash(record)
    {
      id: record.id,
      name: record.name,
      active: record.active
    }
  end

  def with_root_key(value, root_key)
    root_key ? {root_key.to_sym => value} : value
  end

  def record_from(data)
    Record.new(
      id: data.fetch(:id),
      name: data.fetch(:name),
      active: data.fetch(:active)
    )
  end

  def record_arbitrary
    Pbt.fixed_hash(
      id: Pbt.integer(min: -100, max: 100),
      name: Pbt.ascii_string,
      active: Pbt.boolean
    )
  end

  def root_key_arbitrary
    Pbt.one_of(nil, :record, 'record')
  end

  def record_case_arbitrary
    Pbt.fixed_hash(
      record: record_arbitrary,
      root_key: root_key_arbitrary
    )
  end

  def collection_case_arbitrary
    Pbt.fixed_hash(
      records: Pbt.array(record_arbitrary, max: 10, empty: true),
      root_key: root_key_arbitrary
    )
  end
end
