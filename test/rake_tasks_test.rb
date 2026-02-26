# frozen_string_literal: true

require 'test_helper'
require 'rake'
require 'fileutils'
require 'tmpdir'

class RakeTasksTest < Minitest::Test
  def setup
    @original_dir = Dir.pwd
    @temp_dir = Dir.mktmpdir
    Dir.chdir(@temp_dir)
    
    # Load Alba tasks
    Rake.application.clear
    load File.expand_path('../lib/tasks/alba.rake', __dir__)
  end

  def teardown
    Dir.chdir(@original_dir)
    FileUtils.rm_rf(@temp_dir)
    Rake.application.clear
  end

  def test_generate_schemas_task_exists
    assert Rake::Task.task_defined?('alba:generate_schemas')
  end

  def test_generate_schema_task_exists
    assert Rake::Task.task_defined?('alba:generate_schema')
  end

  def test_schema_filename_generation
    test_resource = Class.new do
      include Alba::Resource
      
      def self.name
        'UserAccountResource'
      end
      
      attributes :id, :name
    end
    
    stub_const('UserAccountResource', test_resource)
    
    # Access the private method for testing
    task_methods = Rake.application.tasks.first.instance_eval { self }
    filename = task_methods.send(:generate_schema_filename, test_resource)
    
    assert_equal 'user_account', filename
  end

  def test_find_alba_resources
    # Create test resources
    test_resource1 = Class.new do
      include Alba::Resource
      
      def self.name
        'TestResource1'
      end
      
      attributes :id
    end
    
    test_resource2 = Class.new do
      include Alba::Resource
      
      def self.name
        'TestResource2'
      end
      
      attributes :name
    end
    
    stub_const('TestResource1', test_resource1)
    stub_const('TestResource2', test_resource2)
    
    # Access the private method for testing
    task_methods = Rake.application.tasks.first.instance_eval { self }
    resources = task_methods.send(:find_alba_resources)
    
    resource_names = resources.map(&:name)
    assert_includes resource_names, 'TestResource1'
    assert_includes resource_names, 'TestResource2'
  end

  def test_combined_schema_generation
    test_resource = Class.new do
      include Alba::Resource
      
      def self.name
        'TestResource'
      end
      
      attributes :id, :name
    end
    
    stub_const('TestResource', test_resource)
    
    # Access the private method for testing
    task_methods = Rake.application.tasks.first.instance_eval { self }
    combined = task_methods.send(:generate_combined_schema, [test_resource])
    
    assert_equal 'https://json-schema.org/draft/2020-12/schema', combined['$schema']
    assert combined.key?('$defs')
    assert combined['$defs'].key?('Test')
  end

  private

  def stub_const(name, value)
    Object.const_set(name, value)
  end
end