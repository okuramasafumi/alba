# Based on https://github.com/jsonapi-serializer/comparisons
require_relative '../test_helper'
require 'securerandom'
require 'ffaker'

class CircularAssociationTest < Minitest::Test
  class Author
    attr_accessor :id, :first_name, :last_name, :books, :book_ids

    def initialize(id, first_name, last_name, books, book_ids)
      @id = id
      @first_name = first_name
      @last_name = last_name
      @books = books
      @book_ids = book_ids
    end
  end

  class Genre
    attr_accessor :id, :title, :description, :books, :book_ids

    def initialize(id, title, description, books, book_ids)
      @id = id
      @title = title
      @description = description
      @books = books
      @book_ids = book_ids
    end
  end

  class Book
    attr_accessor :id, :title, :description, :published_at, :authors, :author_ids, :genre, :genre_id

    def initialize(id, title, description, published_at, authors, author_ids, genre, genre_id)
      @id = id
      @title = title
      @description = description
      @published_at = published_at
      @authors = authors
      @author_ids = author_ids
      @genre = genre
      @genre_id = genre_id
    end

    def sync
      self.author_ids = authors.map do |a|
        a.books << self
        a.book_ids << id
        a.id
      end
      self.genre_id = genre.id
      genre.books << self
      genre.book_ids << id

      self
    end
  end

  class AuthorResource
    include Alba::Resource

    key!

    attributes :id, :first_name, :last_name
    has_many :books, resource: 'CircularAssociationTest::BookResource'
  end

  class GenreResource
    include Alba::Resource

    key!

    attributes :id, :title, :description
    has_many :books, resource: 'CircularAssociationTest::BookResource'
  end

  class BookResource
    include Alba::Resource

    key!

    attributes :id, :title, :description, :published_at
    has_many :authors, resource: 'CircularAssociationTest::AuthorResource'
    one :genre, resource: 'CircularAssociationTest::GenreResource'
  end

  def setup
    Alba.enable_inference!

    @authors = Array.new(100) do
      Author.new(
        SecureRandom.uuid,
        FFaker::Name.first_name,
        FFaker::Name.last_name,
        [],
        []
      )
    end

    @genres = Array.new(10) do
      Genre.new(
        SecureRandom.uuid,
        FFaker::Book.genre,
        FFaker::Book.description,
        [],
        []
      )
    end

    @books = Array.new(100) do
      Book.new(
        SecureRandom.uuid,
        FFaker::Book.title,
        FFaker::Book.description,
        FFaker::Time.datetime,
        @authors.sample(rand(1..5)),
        [],
        @genres.sample,
        nil
      ).sync
    end
  end

  def test_included_option_works_for_serialize
    book = @books.sample
    BookResource.new(book, included: {book: {authors: :books, genre: :books}}).serialize
    assert true # No Error
  end

  def test_included_option_with_nil_value_works_for_serialize
    book = @books.sample
    BookResource.new(book, included: nil).serialize
    assert true # No Error
  end

  def test_included_option_with_false_value_works_for_serialize
    book = @books.sample
    BookResource.new(book, included: false).serialize
    assert true # No Error
  end

  def test_included_option_works_for_serializable_hash
    book = @books.sample
    BookResource.new(book, included: {book: {authors: :books, genre: :books}}).serializable_hash
    assert true # No Error
  end

  def test_included_option_works_for_serialize_with_collection
    books = @books.sample(3)
    BookResource.new(books, included: {book: {authors: :books, genre: :books}}).serialize
    assert true # No Error
  end

  def test_included_option_with_nil_end_works_for_serialize
    book = @books.sample
    BookResource.new(book, included: {book: {authors: nil, genre: nil}}).serialize
    assert true # No Error
  end

  def test_included_option_with_array_end_works_for_serialize
    book = @books.sample
    BookResource.new(book, included: {book: [:authors, :genre]}).serialize
    assert true # No Error
  end

  def test_included_option_with_invalid_type
    book = @books.sample
    assert_raises Alba::Error do
      BookResource.new(book, included: 'book').serialize # This is not supported
    end
  end
end
