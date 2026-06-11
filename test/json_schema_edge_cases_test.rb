# frozen_string_literal: true

require 'test_helper'

class JSONSchemaEdgeCasesTest < Minitest::Test
  def test_empty_resource
    empty_resource = Class.new do
      include Alba::Resource
    end
    
    schema = Alba::JSONSchema.generate(empty_resource)
    
    assert_equal 'object', schema['type']
    assert_equal({}, schema['properties'])
    assert_equal [], schema['required']
  end

  def test_resource_with_only_computed_attributes
    computed_resource = Class.new do
      include Alba::Resource
      
      attribute :computed_field do |obj|
        "computed_#{obj.id}"
      end
      
      attribute :another_computed do |obj|
        obj.value * 2
      end
    end
    
    schema = Alba::JSONSchema.generate(computed_resource)
    
    assert_equal 'string', schema['properties']['computed_field']['type']
    assert_equal 'Computed attribute', schema['properties']['computed_field']['description']
    assert_equal 'string', schema['properties']['another_computed']['type']
    assert_equal 'Computed attribute', schema['properties']['another_computed']['description']
  end

  def test_resource_with_circular_references
    # Define two resources that reference each other
    user_resource = Class.new do
      include Alba::Resource
      
      def self.name
        'UserResource'
      end
      
      attributes :id, :name
    end
    
    post_resource = Class.new do
      include Alba::Resource
      
      def self.name
        'PostResource'
      end
      
      attributes :id, :title
      one :author, resource: user_resource
    end
    
    # Add posts association to user (circular reference)
    user_resource.class_eval do
      many :posts, resource: post_resource
    end
    
    schema = Alba::JSONSchema.generate(user_resource)
    
    assert_equal 'object', schema['type']
    assert schema['properties'].key?('posts')
    assert_equal 'array', schema['properties']['posts']['type']
    assert_equal '#/$defs/Post', schema['properties']['posts']['items']['$ref']
    
    # Check that both resources are in definitions
    assert schema['$defs'].key?('Post')
    assert schema['$defs']['Post']['properties'].key?('author')
  end

  def test_resource_with_proc_based_resource_association
    dynamic_resource = Class.new do
      include Alba::Resource
      
      attributes :id, :type
      
      # Dynamic resource selection based on object type
      association :related_object, resource: proc { |obj|
        case obj.type
        when 'user' then UserDynamicResource
        when 'post' then PostDynamicResource
        else GenericDynamicResource
        end
      }
    end
    
    user_dynamic_resource = Class.new do
      include Alba::Resource
      
      def self.name
        'UserDynamicResource'
      end
      
      attributes :id, :username
    end
    
    post_dynamic_resource = Class.new do
      include Alba::Resource
      
      def self.name
        'PostDynamicResource'
      end
      
      attributes :id, :title
    end
    
    generic_dynamic_resource = Class.new do
      include Alba::Resource
      
      def self.name
        'GenericDynamicResource'
      end
      
      attributes :id, :data
    end
    
    stub_const('UserDynamicResource', user_dynamic_resource)
    stub_const('PostDynamicResource', post_dynamic_resource)
    stub_const('GenericDynamicResource', generic_dynamic_resource)
    
    schema = Alba::JSONSchema.generate(dynamic_resource)
    
    # For proc-based resources, we can't know the exact type at schema time
    # So it should default to object type
    assert schema['properties']['related_object']
    assert_equal 'object', schema['properties']['related_object']['type']
    refute schema['properties']['related_object'].key?('$ref')
  end

  def test_resource_with_invalid_transform_type
    invalid_transform_resource = Class.new do
      include Alba::Resource
      
      # This will set an invalid transform type internally
      def self._transform_type
        :invalid_type
      end
      
      attributes :id, :field_name
    end
    
    schema = Alba::JSONSchema.generate(invalid_transform_resource)
    
    # Should fall back to original key names when transformation fails
    assert schema['properties'].key?('field_name')
  end

  def test_resource_with_symbol_keys
    symbol_resource = Class.new do
      include Alba::Resource
      
      attributes :id, :name
      # Force symbolized keys
    end
    
    Alba.symbolize_keys!
    
    schema = Alba::JSONSchema.generate(symbol_resource)
    
    # Schema should still use string keys for JSON Schema compliance
    assert schema['properties'].key?('id')
    assert schema['properties'].key?('name')
  ensure
    Alba.stringify_keys!
  end

  def test_nested_resource_with_empty_block
    empty_nested_resource = Class.new do
      include Alba::Resource
      
      attributes :id
      
      nested_attribute :empty_nested do
        # Empty block
      end
    end
    
    schema = Alba::JSONSchema.generate(empty_nested_resource)
    
    assert_equal 'object', schema['properties']['empty_nested']['type']
    assert_equal({}, schema['properties']['empty_nested']['properties'])
  end

  def test_resource_with_nil_association_resource
    nil_association_resource = Class.new do
      include Alba::Resource
      
      attributes :id
      
      # Association with explicit resource as nil for this test
      association :related_items do
        attributes :id, :name
      end
    end
    
    # This should work - association with block doesn't need inflector
    schema = Alba::JSONSchema.generate(nil_association_resource)
    
    assert_equal 'array', schema['properties']['related_items']['type']
    # Inline associations create anonymous resources that get referenced via $ref
    assert schema['properties']['related_items']['items']['$ref']
  end

  def test_resource_with_custom_types
    # Register a custom type
    Alba.register_type(:email, 
      check: ->(value) { value.is_a?(String) && value.include?('@') },
      converter: ->(value) { value.to_s.downcase },
      auto_convert: true
    )
    
    custom_type_resource = Class.new do
      include Alba::Resource
      
      attributes :id, email: :email, tags: :ArrayOfString
    end
    
    schema = Alba::JSONSchema.generate(custom_type_resource)
    
    # Custom types should be handled gracefully
    assert_equal 'string', schema['properties']['email']['type']
    assert schema['properties']['email']['description'].include?('Custom type')
    
    # Array types should work correctly
    assert_equal 'array', schema['properties']['tags']['type']
    assert_equal 'string', schema['properties']['tags']['items']['type']
  ensure
    # Clean up custom type
    Alba.instance_variable_get(:@types).delete(:email)
  end

  def test_resource_with_meta_information
    meta_resource = Class.new do
      include Alba::Resource
      
      root_key :item
      attributes :id, :name
      
      meta do
        { count: object.is_a?(Array) ? object.size : 1 }
      end
    end
    
    schema = Alba::JSONSchema.generate(meta_resource)
    
    # Meta doesn't affect the core object schema
    item_props = schema['properties']['item']['properties']
    assert item_props.key?('id')
    assert item_props.key?('name')
    
    # Meta should not appear in the schema as it's runtime-dependent
    refute item_props.key?('meta')
  end

  def test_resource_with_conditional_attributes_without_params
    conditional_resource = Class.new do
      include Alba::Resource
      
      attributes :id, :name
      attributes :secret_field, if: proc { |obj| obj.admin? }
      attribute :computed_field, if: proc { |obj| obj.visible? } do |obj|
        "computed_#{obj.id}"
      end
    end
    
    schema = Alba::JSONSchema.generate(conditional_resource)
    
    # Conditional attributes should still appear in schema
    # as we can't evaluate conditions at schema generation time
    assert schema['properties'].key?('secret_field')
    assert schema['properties'].key?('computed_field')
    assert_equal 'Computed attribute', schema['properties']['computed_field']['description']
  end

  def test_resource_with_helper_methods
    helper_module = Module.new do
      def format_date(date)
        date.strftime('%Y-%m-%d')
      end
    end
    
    helper_resource = Class.new do
      include Alba::Resource
      
      helper helper_module
      
      attributes :id
      attribute :formatted_date do |obj|
        format_date(obj.created_at)
      end
    end
    
    schema = Alba::JSONSchema.generate(helper_resource)
    
    assert schema['properties'].key?('formatted_date')
    assert_equal 'string', schema['properties']['formatted_date']['type']
    assert_equal 'Computed attribute', schema['properties']['formatted_date']['description']
  end

  def test_resource_with_very_deep_nesting
    deep_resource = Class.new do
      include Alba::Resource
      
      attributes :id
      
      nested_attribute :level1 do
        attributes :field1
        
        nested_attribute :level2 do
          attributes :field2
          
          nested_attribute :level3 do
            attributes :field3
            
            nested_attribute :level4 do
              attributes :field4
              
              nested_attribute :level5 do
                attributes :field5
              end
            end
          end
        end
      end
    end
    
    schema = Alba::JSONSchema.generate(deep_resource)
    
    # Navigate through the deep structure
    level1 = schema['properties']['level1']
    assert_equal 'object', level1['type']
    assert level1['properties'].key?('field1')
    
    level2 = level1['properties']['level2']
    assert_equal 'object', level2['type']
    assert level2['properties'].key?('field2')
    
    level3 = level2['properties']['level3']
    assert_equal 'object', level3['type']
    assert level3['properties'].key?('field3')
    
    level4 = level3['properties']['level4']
    assert_equal 'object', level4['type']
    assert level4['properties'].key?('field4')
    
    level5 = level4['properties']['level5']
    assert_equal 'object', level5['type']
    assert level5['properties'].key?('field5')
  end

  def test_anonymous_resource_classes
    # Test with completely anonymous class
    anonymous_resource = Class.new do
      include Alba::Resource
      
      attributes :id, :value
    end
    
    schema = Alba::JSONSchema.generate(anonymous_resource)
    
    assert_equal 'object', schema['type']
    assert schema['properties'].key?('id')
    assert schema['properties'].key?('value')
  end

  def test_resource_with_all_attribute_types_combined
    comprehensive_resource = Class.new do
      include Alba::Resource
      
      # Simple attributes
      attributes :id, :name
      
      # Typed attributes
      attributes title: String, count: Integer, active: :Boolean
      
      # Computed attributes
      attribute :computed do |obj|
        "computed_value"
      end
      
      # Nested attributes
      nested_attribute :nested do
        attributes :nested_field
        
        attribute :nested_computed do |obj|
          "nested_computed"
        end
      end
      
      # Associations with blocks (will work without inflector)
      association :simple_association do
        attributes :id, :name
      end
      association :collection_items do  # Plural name suggests collection
        attributes :id, :value
      end
      
      # Traits
      trait :extra_fields do
        attributes :extra1, :extra2
      end
    end
    
    schema = Alba::JSONSchema.generate(comprehensive_resource, traits: [:extra_fields])
    
    props = schema['properties']
    
    # Verify all types are handled
    assert_equal 'string', props['id']['type']
    assert_equal 'string', props['title']['type']
    assert_equal 'integer', props['count']['type']
    assert_equal 'boolean', props['active']['type']
    assert_equal 'string', props['computed']['type']
    assert_equal 'object', props['nested']['type']
    # Inline associations create references
    assert props['simple_association']['$ref']
    assert_equal 'array', props['collection_items']['type']
    
    # Verify trait attributes
    assert props.key?('extra1')
    assert props.key?('extra2')
  end

  private

  def stub_const(name, value)
    Object.const_set(name, value)
  end
end