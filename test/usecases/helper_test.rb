# frozen_string_literal: true

require_relative '../test_helper'

class HelperTest < Minitest::Test
  class Library
    def id
      1
    end

    def library_books
      [Book.new]
    end
  end

  class Book
    def id
      2
    end

    def author
      Author.new
    end
  end

  class Author
    def id
      3
    end

    def name
      'The author'
    end
  end

  class ApplicationResource
    include Alba::Resource

    helper do
      def with_id
        attributes :id
      end
    end
  end

  class LibraryResource < ApplicationResource
    with_id

    helper do
      def with_name
        attributes :name
      end
    end

    has_many :library_books do
      with_id

      has_one :author do
        with_id
        with_name
      end
    end
  end

  def test_using_baseclass_method_in_block
    assert_equal(
      '{"id":1,"library_books":[{"id":2,"author":{"id":3,"name":"The author"}}]}',
      LibraryResource.new(Library.new).serialize
    )
  end
end
