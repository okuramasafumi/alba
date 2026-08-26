# frozen_string_literal: true

begin
  require 'alba'
rescue LoadError
  require_relative '../lib/alba'
end

module HelpersForInlineAssociationsExample
  class Book
    attr_reader :id, :title

    def initialize(id, title)
      @id = id
      @title = title
    end
  end

  class Library
    attr_reader :id, :name, :books

    def initialize(id, name, books)
      @id = id
      @name = name
      @books = books
    end
  end

  class ApplicationResource
    include Alba::Resource

    helper do
      def with_id
        # @type self: singleton(ApplicationResource)
        attributes(:id)
      end

      def with_title
        # @type self: singleton(ApplicationResource)
        attributes(:title)
      end
    end
  end

  class LibraryResource < ApplicationResource
    with_id
    attributes :name

    many :books do
      # @type self: singleton(LibraryResource)
      with_id
      with_title
    end
  end

  library = Library.new(1, 'Central', [Book.new(10, 'Alba 101')])
  puts LibraryResource.new(library).serialize
end
