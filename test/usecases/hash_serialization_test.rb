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

  class InstanceMethodHashResource
    include Alba::Resource

    attributes :id, :name, :id_name

    def id_name(hash)
      "#{hash[:id]}#{hash[:name]}"
    end
  end

  def test_hash_serialization_with_instance_method
    hash = {id: 1, name: 'test'}
    assert_equal(
      '{"id":1,"name":"test","id_name":"1test"}',
      InstanceMethodHashResource.new(hash).serialize
    )
  end

  class HashWithMissingKeysResource
    include Alba::Resource

    attributes :id, :name, :email
  end

  def test_hash_serialization_with_missing_keys
    hash = {id: 1, name: 'test'}
    assert_equal(
      '{"id":1,"name":"test","email":null}',
      HashWithMissingKeysResource.new(hash).serialize
    )
  end

  class HashLike < Hash
    def fetch(key, *args)
      super(key.to_s, *args)
    end
  end

  def test_hash_like_serialization_with_missing_keys
    hash = HashLike['id' => 1, 'name' => 'test'] # rubocop:disable Style/StringHashKeys
    assert_equal(
      '{"id":1,"name":"test","email":null}',
      HashWithMissingKeysResource.new(hash).serialize
    )
  end

  class PreferObjectMethodHashResource
    include Alba::Resource

    prefer_object_method!

    attributes :id, :name, :email
  end

  def test_hash_serialization_with_missing_keys_prefer_object_method
    hash = {id: 1, name: 'test'}
    assert_equal(
      '{"id":1,"name":"test","email":null}',
      PreferObjectMethodHashResource.new(hash).serialize
    )
  end
end
