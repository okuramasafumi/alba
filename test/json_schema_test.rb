# frozen_string_literal: true

require 'test_helper'

class JSONSchemaTest < Minitest::Test
  class SimpleResource
    include Alba::Resource
    
    attributes :id, :name
  end

  class TypedResource
    include Alba::Resource
    
    attributes :id, name: String, age: Integer, active: :Boolean
  end

  class ResourceWithAssociations
    include Alba::Resource
    
    attributes :id, :title
    one :author, resource: SimpleResource
    many :comments, resource: SimpleResource
  end

  class ResourceWithNestedAttributes
    include Alba::Resource
    
    attributes :id, :name
    
    nested_attribute :address do
      attributes :street, :city, :country
    end
  end

  class ResourceWithRootKey
    include Alba::Resource
    
    root_key :user, :users
    attributes :id, :name
  end

  class ResourceWithKeyTransformation
    include Alba::Resource
    
    transform_keys :lower_camel
    attributes :id, :first_name, :last_name
  end

  class ResourceWithTraits
    include Alba::Resource
    
    attributes :id, :name
    
    trait :with_email do
      attributes :email
    end
    
    trait :with_timestamps do
      attributes :created_at, :updated_at
    end
  end

  def test_simple_resource_schema_generation
    schema = Alba::JSONSchema.generate(SimpleResource)
    
    assert_equal 'https://json-schema.org/draft/2020-12/schema', schema['$schema']
    assert_equal 'object', schema['type']
    assert schema['properties'].key?('id')
    assert schema['properties'].key?('name')
    assert_equal 'string', schema['properties']['id']['type']
    assert_equal 'string', schema['properties']['name']['type']
  end

  def test_typed_resource_schema_generation
    schema = Alba::JSONSchema.generate(TypedResource)
    
    assert_equal 'string', schema['properties']['id']['type']
    assert_equal 'string', schema['properties']['name']['type']
    assert_equal 'integer', schema['properties']['age']['type']
    assert_equal 'boolean', schema['properties']['active']['type']
  end

  def test_resource_with_associations_schema_generation
    schema = Alba::JSONSchema.generate(ResourceWithAssociations)
    
    assert_equal 'object', schema['type']
    assert schema['properties'].key?('author')
    assert schema['properties'].key?('comments')
    
    # Check association schemas
    assert_equal '#/$defs/Simple', schema['properties']['author']['$ref']
    assert_equal 'array', schema['properties']['comments']['type']
    assert_equal '#/$defs/Simple', schema['properties']['comments']['items']['$ref']
    
    # Check definitions are included
    assert schema.key?('$defs')
    assert schema['$defs'].key?('Simple')
  end

  def test_resource_with_nested_attributes_schema_generation
    schema = Alba::JSONSchema.generate(ResourceWithNestedAttributes)
    
    assert_equal 'object', schema['type']
    assert schema['properties'].key?('address')
    assert_equal 'object', schema['properties']['address']['type']
    
    address_props = schema['properties']['address']['properties']
    assert address_props.key?('street')
    assert address_props.key?('city')
    assert address_props.key?('country')
  end

  def test_resource_with_root_key_schema_generation
    schema = Alba::JSONSchema.generate(ResourceWithRootKey)
    
    # Should wrap the schema with root key
    assert schema['properties'].key?('user')
    assert_equal ['user'], schema['required']
    
    user_schema = schema['properties']['user']
    assert_equal 'object', user_schema['type']
    assert user_schema['properties'].key?('id')
    assert user_schema['properties'].key?('name')
  end

  def test_resource_with_key_transformation_schema_generation
    # This requires inflector to be set
    Alba.inflector = :active_support
    
    schema = Alba::JSONSchema.generate(ResourceWithKeyTransformation)
    
    # Keys should be transformed
    assert schema['properties'].key?('id')
    assert schema['properties'].key?('firstName')
    assert schema['properties'].key?('lastName')
    refute schema['properties'].key?('first_name')
    refute schema['properties'].key?('last_name')
  ensure
    Alba.inflector = nil
  end

  def test_resource_with_traits_schema_generation
    schema = Alba::JSONSchema.generate(ResourceWithTraits, traits: [:with_email])
    
    # Should include trait attributes
    assert schema['properties'].key?('id')
    assert schema['properties'].key?('name')
    assert schema['properties'].key?('email')
  end

  def test_resource_with_multiple_traits_schema_generation
    schema = Alba::JSONSchema.generate(ResourceWithTraits, traits: [:with_email, :with_timestamps])
    
    # Should include all trait attributes
    assert schema['properties'].key?('id')
    assert schema['properties'].key?('name')
    assert schema['properties'].key?('email')
    assert schema['properties'].key?('created_at')
    assert schema['properties'].key?('updated_at')
  end

  def test_schema_generation_with_title_and_description
    schema = Alba::JSONSchema.generate(
      SimpleResource, 
      title: 'User Schema',
      description: 'Schema for user resources'
    )
    
    assert_equal 'User Schema', schema['title']
    assert_equal 'Schema for user resources', schema['description']
  end

  def test_schema_generation_without_definitions_when_no_associations
    schema = Alba::JSONSchema.generate(SimpleResource)
    
    refute schema.key?('$defs')
  end

  def test_custom_type_handling
    Alba.register_type(:iso8601, converter: ->(time) { time.iso8601 }, auto_convert: true)
    
    custom_resource = Class.new do
      include Alba::Resource
      
      attributes :id, created_at: :iso8601
    end
    
    schema = Alba::JSONSchema.generate(custom_resource)
    
    created_at_prop = schema['properties']['created_at']
    assert_equal 'string', created_at_prop['type']
    assert created_at_prop['description'].include?('Custom type')
  ensure
    # Clean up custom type
    Alba.instance_variable_get(:@types).delete(:iso8601)
  end

  def test_computed_attribute_handling
    computed_resource = Class.new do
      include Alba::Resource
      
      attributes :id
      
      attribute :full_name do |obj|
        "#{obj.first_name} #{obj.last_name}"
      end
    end
    
    schema = Alba::JSONSchema.generate(computed_resource)
    
    full_name_prop = schema['properties']['full_name']
    assert_equal 'string', full_name_prop['type']
    assert_equal 'Computed attribute', full_name_prop['description']
  end

  def test_array_type_handling
    array_resource = Class.new do
      include Alba::Resource
      
      attributes :id, tags: :ArrayOfString, scores: :ArrayOfInteger
    end
    
    schema = Alba::JSONSchema.generate(array_resource)
    
    tags_prop = schema['properties']['tags']
    assert_equal 'array', tags_prop['type']
    assert_equal 'string', tags_prop['items']['type']
    
    scores_prop = schema['properties']['scores']
    assert_equal 'array', scores_prop['type']
    assert_equal 'integer', scores_prop['items']['type']
  end

  def test_empty_required_fields
    schema = Alba::JSONSchema.generate(SimpleResource)
    
    # Currently all fields are optional
    assert_equal [], schema['required']
  end

  def test_anonymous_resource_handling
    inline_schema = Alba::JSONSchema.generate(
      Class.new do
        include Alba::Resource
        attributes :id, :name
      end
    )
    
    assert_equal 'object', inline_schema['type']
    assert inline_schema['properties'].key?('id')
    assert inline_schema['properties'].key?('name')
  end
end