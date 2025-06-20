# frozen_string_literal: true

require 'set'

module Alba
  # Generates JSON Schema from Alba resources
  class JSONSchema
    # @param resource_class [Class<Alba::Resource>] the resource class to generate schema for
    # @param options [Hash] options for schema generation
    # @option options [Array<Symbol>] :traits traits to include in schema
    # @option options [Boolean] :include_meta whether to include metadata in schema
    # @option options [String] :title schema title
    # @option options [String] :description schema description
    # @return [Hash] JSON Schema as a Hash
    def self.generate(resource_class, **options)
      new(resource_class, **options).generate
    end

    def initialize(resource_class, **options)
      @resource_class = resource_class
      @options = options
      @definitions = options[:_definitions] || {}
      @processing = options[:_processing] || Set.new
    end

    # Generate JSON Schema
    #
    # @return [Hash] JSON Schema
    def generate
      schema = {
        '$schema' => 'https://json-schema.org/draft/2020-12/schema',
        'type' => 'object'
      }

      schema['title'] = @options[:title] if @options[:title]
      schema['description'] = @options[:description] if @options[:description]

      properties = generate_properties
      schema['properties'] = properties
      schema['required'] = generate_required_fields(properties)

      # Handle root key wrapping
      if has_root_key?
        schema = wrap_with_root_key(schema)
      end

      # Add definitions for referenced resources
      schema['$defs'] = @definitions unless @definitions.empty?

      schema
    end

    private

    def generate_properties
      properties = {}

      # Include traits if specified
      if @options[:traits]
        trait_properties = generate_trait_properties
        properties.merge!(trait_properties)
      end

      # Process attributes
      @resource_class._attributes.each do |key, attr_def|
        property = property_for_attribute(key, attr_def)
        properties[transform_key(key)] = property if property
      end

      properties
    end

    def generate_trait_properties
      properties = {}
      Array(@options[:traits]).each do |trait_name|
        trait_body = @resource_class._traits[trait_name]
        next unless trait_body

        # Create a temporary resource class to evaluate the trait
        temp_class = Class.new
        temp_class.include(Alba::Resource)
        temp_class.class_eval(&trait_body)

        temp_class._attributes.each do |key, attr_def|
          property = property_for_attribute(key, attr_def)
          properties[transform_key(key)] = property if property
        end
      end
      properties
    end

    def property_for_attribute(key, attr_def)
      case attr_def
      when Symbol
        # Simple attribute
        { 'type' => 'string' }
      when Alba::TypedAttribute
        property_for_typed_attribute(attr_def)
      when Alba::Association
        property_for_association(attr_def)
      when Alba::NestedAttribute
        property_for_nested_attribute(attr_def)
      when Alba::ConditionalAttribute
        property_for_attribute(key, attr_def.instance_variable_get(:@body))
      when Proc
        # Computed attribute - we can't know the type, so default to string
        { 'type' => 'string', 'description' => 'Computed attribute' }
      else
        { 'type' => 'string' }
      end
    end

    def property_for_typed_attribute(typed_attr)
      schema = {}
      
      # Access the type through the internal @type instance variable
      type = typed_attr.instance_variable_get(:@type)
      type_name = type&.name
      
      if type_name == String
        schema['type'] = 'string'
      elsif type_name == Integer
        schema['type'] = 'integer'
      elsif type_name == :Boolean
        schema['type'] = 'boolean'
      elsif type_name == Float
        schema['type'] = 'number'
      elsif type_name.to_s =~ /\AArrayOf(.+)\z/
        element_type = Regexp.last_match(1).downcase
        schema = {
          'type' => 'array',
          'items' => { 'type' => element_type }
        }
      else
        # Custom type or unknown type
        schema['type'] = 'string'
        schema['description'] = "Custom type: #{type_name}"
      end

      schema
    end

    def property_for_association(association)
      # Since Alba doesn't distinguish between one/many in the Association class,
      # we'll use a simple heuristic: assume plural names are collections
      association_name = association.name.to_s
      
      # Simple pluralization check: if name ends with 's' and length > 1, assume collection
      is_collection = association_name.length > 1 && association_name.end_with?('s')
      
      resource = association.instance_variable_get(:@resource)
      
      # Handle proc-based resources - we can't determine the type at schema time
      if resource.is_a?(Proc)
        return { 'type' => 'object' } unless is_collection
        return {
          'type' => 'array',
          'items' => { 'type' => 'object' }
        }
      end
      
      if is_collection
        items_schema = if resource
                         ref_name = generate_definition_name(resource)
                         add_resource_definition(ref_name, resource)
                         { '$ref' => "#/$defs/#{ref_name}" }
                       else
                         { 'type' => 'object' }
                       end
        
        {
          'type' => 'array',
          'items' => items_schema
        }
      else
        if resource
          ref_name = generate_definition_name(resource)
          add_resource_definition(ref_name, resource)
          { '$ref' => "#/$defs/#{ref_name}" }
        else
          { 'type' => 'object' }
        end
      end
    end

    def property_for_nested_attribute(nested_attr)
      # Create a temporary resource class to evaluate the nested block
      temp_class = Alba.resource_class
      temp_class.class_eval(&nested_attr.instance_variable_get(:@block))
      
      properties = {}
      temp_class._attributes.each do |key, attr_def|
        property = property_for_attribute(key, attr_def)
        properties[transform_key(key)] = property if property
      end

      {
        'type' => 'object',
        'properties' => properties
      }
    end

    def generate_required_fields(properties)
      # For now, we'll consider all properties as optional
      # In the future, this could be enhanced to detect required fields
      # based on validations or other indicators
      []
    end

    def has_root_key?
      @resource_class._key || @resource_class._key_for_collection
    end

    def wrap_with_root_key(schema)
      key = @resource_class._key || @resource_class._key_for_collection
      root_key = key.is_a?(Array) ? key.first : key
      
      transformed_key = transform_key(root_key)
      
      wrapped_schema = {
        '$schema' => 'https://json-schema.org/draft/2020-12/schema',
        'type' => 'object',
        'properties' => {
          transformed_key => schema
        },
        'required' => [transformed_key]
      }
      
      # Move title and description to the outer schema
      if schema['title']
        wrapped_schema['title'] = schema['title']
        schema.delete('title')
      end
      
      if schema['description']
        wrapped_schema['description'] = schema['description']
        schema.delete('description')
      end
      
      wrapped_schema
    end

    def transform_key(key)
      return key.to_s unless @resource_class._transform_type != :none
      return key.to_s unless Alba.inflector

      Alba.transform_key(key, transform_type: @resource_class._transform_type)
    rescue Alba::Error
      # If transformation fails, return original key
      key.to_s
    end

    def generate_definition_name(resource_class)
      return resource_class.to_s if resource_class.is_a?(String)
      
      name = if resource_class.respond_to?(:name) && resource_class.name
               resource_class.name
             else
               'AnonymousResource'
             end
      
      # Remove namespacing and common suffixes
      name = name.split('::').last if name.include?('::')
      name.gsub(/Resource$|Serializer$/, '')
    end

    def add_resource_definition(name, resource_class)
      return if @definitions.key?(name)
      return unless resource_class.respond_to?(:_attributes)
      
      # Check if we're already processing this resource to prevent infinite recursion
      resource_key = resource_class.object_id
      return if @processing.include?(resource_key)

      # Mark this resource as being processed
      @processing.add(resource_key)

      # Add a placeholder to prevent infinite recursion in self-references
      @definitions[name] = { 'type' => 'object', 'properties' => {} }

      # Generate schema for the referenced resource with shared definitions
      options = @options.reject { |k, _| [:title, :description].include?(k) }
      options[:_definitions] = @definitions
      options[:_processing] = @processing
      
      definition_generator = self.class.new(resource_class, **options)
      definition_schema = definition_generator.generate
      
      # Remove the $schema key from definition
      definition_schema.delete('$schema')
      
      # Merge any nested definitions into our main definitions hash
      if definition_schema['$defs']
        @definitions.merge!(definition_schema['$defs'])
        definition_schema.delete('$defs')
      end
      
      # Replace the placeholder with the actual schema
      @definitions[name] = definition_schema
      
      # Remove from processing set
      @processing.delete(resource_key)
    end
  end
end