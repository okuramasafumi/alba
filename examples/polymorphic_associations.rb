# frozen_string_literal: true

begin
  require 'alba'
rescue LoadError
  require_relative '../lib/alba'
end

class FolderNode
  attr_reader :name, :children

  def initialize(name, children = [])
    @name = name
    @children = children
  end
end

class FileNode
  attr_reader :name, :size

  def initialize(name, size)
    @name = name
    @size = size
  end
end

class FileNodeResource
  include Alba::Resource

  attributes :name, :size

  attribute :type do
    'file'
  end
end

class FolderNodeResource
  include Alba::Resource

  attributes :name

  attribute :type do
    'folder'
  end

  many :children,
       resource: lambda { |node|
         case node
         when FolderNode
           FolderNodeResource
         when FileNode
           FileNodeResource
         else
           raise Alba::Error, "Unsupported node: #{node.class}"
         end
       }
end

tree = FolderNode.new('root', [FileNode.new('README.md', 1200), FolderNode.new('lib', [FileNode.new('alba.rb', 3200)])])

puts FolderNodeResource.new(tree).serialize
