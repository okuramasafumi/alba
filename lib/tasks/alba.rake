# frozen_string_literal: true

require 'fileutils'

namespace :alba do
  desc "Generate JSON schemas for all Alba resources"
  task :generate_schemas do
    require_relative '../alba'
    
    output_dir = ENV['OUTPUT_DIR'] || 'schemas'
    FileUtils.mkdir_p(output_dir)
    
    # Find all resource classes
    resource_classes = find_alba_resources
    
    if resource_classes.empty?
      puts "No Alba resources found. Make sure your resources are loaded."
      next
    end
    
    puts "Found #{resource_classes.size} Alba resource(s)"
    
    resource_classes.each do |resource_class|
      begin
        schema = Alba::JSONSchema.generate(resource_class)
        schema_name = generate_schema_filename(resource_class)
        
        schema_path = File.join(output_dir, "#{schema_name}.json")
        File.write(schema_path, JSON.pretty_generate(schema))
        
        puts "Generated schema for #{resource_class.name} -> #{schema_path}"
      rescue => e
        puts "Error generating schema for #{resource_class.name}: #{e.message}"
      end
    end
    
    # Generate combined schema file with all definitions
    begin
      combined_schema = generate_combined_schema(resource_classes)
      combined_path = File.join(output_dir, 'combined_schema.json')
      File.write(combined_path, JSON.pretty_generate(combined_schema))
      puts "Generated combined schema -> #{combined_path}"
    rescue => e
      puts "Error generating combined schema: #{e.message}"
    end
    
    puts "\nSchema generation completed! Files saved in #{output_dir}/"
  end

  desc "Generate JSON schema for a specific Alba resource"
  task :generate_schema, [:resource_name] do |_task, args|
    require_relative '../alba'
    
    resource_name = args[:resource_name]
    
    if resource_name.nil? || resource_name.empty?
      puts "Usage: rake alba:generate_schema[ResourceName]"
      puts "Example: rake alba:generate_schema[UserResource]"
      next
    end
    
    begin
      resource_class = Object.const_get(resource_name)
      
      unless resource_class.included_modules.include?(Alba::Resource)
        puts "Error: #{resource_name} does not include Alba::Resource"
        next
      end
      
      schema = Alba::JSONSchema.generate(resource_class)
      schema_name = generate_schema_filename(resource_class)
      
      output_dir = ENV['OUTPUT_DIR'] || 'schemas'
      FileUtils.mkdir_p(output_dir)
      
      schema_path = File.join(output_dir, "#{schema_name}.json")
      File.write(schema_path, JSON.pretty_generate(schema))
      
      puts "Generated schema for #{resource_name} -> #{schema_path}"
    rescue NameError
      puts "Error: Resource class '#{resource_name}' not found"
    rescue => e
      puts "Error generating schema: #{e.message}"
    end
  end

  private

  def find_alba_resources
    # Use ObjectSpace to find all classes that include Alba::Resource
    ObjectSpace.each_object(Class).select do |klass|
      klass.included_modules.include?(Alba::Resource) && 
      klass.name && 
      !klass.name.empty? &&
      klass != Alba::Resource
    end.sort_by(&:name)
  end

  def generate_schema_filename(resource_class)
    name = resource_class.name
    
    # Convert CamelCase to snake_case and remove common suffixes
    name.gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
        .gsub(/([a-z\d])([A-Z])/, '\1_\2')
        .downcase
        .gsub(/_resource$|_serializer$/, '')
  end

  def generate_combined_schema(resource_classes)
    definitions = {}
    
    resource_classes.each do |resource_class|
      begin
        schema = Alba::JSONSchema.generate(resource_class, include_meta: false)
        # Remove $schema from individual definitions
        schema.delete('$schema')
        
        def_name = generate_schema_filename(resource_class).tr('_', ' ').split.map(&:capitalize).join
        definitions[def_name] = schema
      rescue => e
        puts "Warning: Could not include #{resource_class.name} in combined schema: #{e.message}"
      end
    end
    
    {
      '$schema' => 'https://json-schema.org/draft/2020-12/schema',
      'title' => 'Alba Resources Combined Schema',
      'description' => 'Combined JSON Schema for all Alba resources',
      '$defs' => definitions
    }
  end
end