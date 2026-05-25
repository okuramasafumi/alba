# frozen_string_literal: true

require 'test_helper'
require 'json'
require 'pbt'

class PbtConditionalAttributesTest < Minitest::Test
  Record = Struct.new(:id, :name, :score, :enabled, :label, keyword_init: true)

  class RecordResource
    include Alba::Resource

    attributes :id
    attributes :name, if: proc { params[:include_name] }
    attributes :score, if: proc { |record, score| record.enabled || score.even? }

    attribute :label, if: proc { |_record, label| label.end_with?('!') } do |record| # rubocop:disable Style/SymbolProc
      record.label
    end
  end

  def test_conditional_attributes_output_expected_json_shape
    Pbt.assert(worker: :none) do
      Pbt.property(record_case_arbitrary) do |data|
        record = record_from(data.fetch(:record))
        params = {include_name: data.fetch(:include_name)}

        assert_equal(
          expected_record_hash(record, params),
          JSON.parse(RecordResource.new(record, params: params).serialize, symbolize_names: true)
        )
      end
    end
  end

  def test_conditional_attributes_output_expected_json_shape_for_collection
    Pbt.assert(worker: :none) do
      Pbt.property(collection_case_arbitrary) do |data|
        records = data.fetch(:records).map { |record_data| record_from(record_data) }
        params = {include_name: data.fetch(:include_name)}

        assert_equal(
          records.map { |record| expected_record_hash(record, params) },
          JSON.parse(RecordResource.new(records, params: params).serialize, symbolize_names: true)
        )
      end
    end
  end

  private

  def expected_record_hash(record, params)
    hash = {id: record.id}
    hash[:name] = record.name if params[:include_name]
    hash[:score] = record.score if record.enabled || record.score.even?
    hash[:label] = record.label if record.label.end_with?('!')
    hash
  end

  def record_from(data)
    Record.new(
      id: data.fetch(:id),
      name: data.fetch(:name),
      score: data.fetch(:score),
      enabled: data.fetch(:enabled),
      label: label_from(data.fetch(:label))
    )
  end

  def label_from(data)
    label = data.fetch(:value)
    data.fetch(:with_exclamation) ? "#{label}!" : label
  end

  def record_arbitrary
    Pbt.fixed_hash(
      id: Pbt.integer(min: -100, max: 100),
      name: Pbt.ascii_string,
      score: Pbt.integer(min: -100, max: 100),
      enabled: Pbt.boolean,
      label: label_arbitrary
    )
  end

  def label_arbitrary
    Pbt.fixed_hash(
      value: Pbt.ascii_string,
      with_exclamation: Pbt.boolean
    )
  end

  def record_case_arbitrary
    Pbt.fixed_hash(
      record: record_arbitrary,
      include_name: Pbt.boolean
    )
  end

  def collection_case_arbitrary
    Pbt.fixed_hash(
      records: Pbt.array(record_arbitrary, max: 10, empty: true),
      include_name: Pbt.boolean
    )
  end
end
