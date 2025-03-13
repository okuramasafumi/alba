# frozen_string_literal: true

require_relative '../test_helper'

class HashSerializationTest < Minitest::Test
  class HashResource
    include Alba::Resource

    attributes :id, :name
  end

  def test_simple_hash_serialization
    hash = {id: 1, name: 'test'}
    assert_equal(
      '{"id":1,"name":"test"}',
      HashResource.new(hash).serialize
    )

    extra_hash = {id: 1, name: 'test', do_not_display: 42}
    assert_equal(
      '{"id":1,"name":"test"}',
      HashResource.new(extra_hash).serialize
    )
  end

  class ManyHashResource
    include Alba::Resource

    many :items, resource: HashResource
  end

  def test_hash_serialization_with_many
    hash = {items: [{id: 1, name: 'test1', do_not_display: 42}, {id: 2, name: 'test2'}]}
    assert_equal(
      '{"items":[{"id":1,"name":"test1"},{"id":2,"name":"test2"}]}',
      ManyHashResource.new(hash).serialize
    )
  end
end
