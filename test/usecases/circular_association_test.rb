# frozen_string_literal: true

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

    root_key!

    attributes :id, :first_name, :last_name
    has_many :books, resource: 'CircularAssociationTest::BookResource'
  end

  class GenreResource
    include Alba::Resource

    root_key!

    attributes :id, :title, :description
    has_many :books, resource: 'CircularAssociationTest::BookResource'
  end

  class BookResource
    include Alba::Resource

    root_key!

    attributes :id, :title, :description, :published_at
    has_many :authors, resource: 'CircularAssociationTest::AuthorResource'
    one :genre, resource: 'CircularAssociationTest::GenreResource'
  end

  def setup
    @original_inflector = Alba.inflector
    Alba.inflector = :active_support

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

  def teardown
    Alba.inflector = @original_inflector
  end

  def test_within_option_works_for_serialize
    book = @books.sample
    result = JSON.parse(BookResource.new(book, within: {authors: :books, genre: :books}).serialize)
    assert result['book']['authors'][0]['books']
    assert books = result.dig('book', 'genre', 'books')
    refute books.first['authors']
  end

  def test_within_option_that_deeply_nested
    book = @books.sample
    result = JSON.parse(BookResource.new(book, within: {authors: {books: {authors: :books}}, genre: :books}).serialize)
    assert result['book']['authors'][0]['books'][0]['authors'][0]['books']
    obj = result['book']['authors'][0]['books'][0]['authors'][0]['books'][0]
    refute obj.key?('authors')
    refute result['book']['authors'][0]['books'][0]['authors'][0]['books'][0]['authors']
  end

  def test_within_ignores_typo
    book = @books.sample
    result = JSON.parse(BookResource.new(book, within: {authors: :boks, genre: :boks}).serialize)
    assert result['book']['authors']
    refute result['book']['authors'][0]['books']
    refute result.dig('book', 'genre', 'books')
  end

  def test_within_option_with_nil_value_works_for_serialize
    book = @books.sample
    result = JSON.parse(BookResource.new(book, within: nil).serialize)
    assert result['book']
    refute result['book'].key?('authors')
    refute result.dig('book', 'authors')
  end

  def test_within_option_with_false_value_works_for_serialize
    book = @books.sample
    result = JSON.parse(BookResource.new(book, within: false).serialize)
    assert result['book']
    refute result.dig('book', 'authors')
  end

  def test_within_option_works_for_serialize_with_collection
    books = @books.sample(3)
    result = JSON.parse(BookResource.new(books, within: {authors: :books, genre: :books}).serialize(root_key: :books))
    assert books = result['books']
    assert books[0]['authors'][0]['books']
    refute books[0]['authors'][0]['books'][0]['authors']
  end

  def test_within_option_with_array_end_works_for_serialize
    book = @books.sample
    result = JSON.parse(BookResource.new(book, within: [:authors, :genre]).serialize)
    assert authors = result.dig('book', 'authors')
    refute authors[0]['books']
    refute result.dig('book', 'genre', 'books')
  end

  def test_within_option_with_array_end_that_does_not_include_all_associations
    book = @books.sample
    result = JSON.parse(BookResource.new(book, within: [:authors]).serialize)
    assert result['book']['authors']
    refute result['book']['genre']
  end

  def test_within_option_with_invalid_type
    book = @books.sample
    assert_raises Alba::Error do
      BookResource.new(book, within: 'book').serialize # This is not supported
    end
  end

  class User
    attr_accessor :id, :full_name, :company

    def type
      'users'
    end
  end

  class Company
    attr_accessor :id, :name, :users

    def type
      'companies'
    end
  end

  class UserResource
    include Alba::Resource

    attributes :type, :id

    nested_attribute :attributes do
      attributes :full_name
    end

    nested_attribute :relationships do
      has_one :company, resource: CompanyResource
    end
  end

  class CompanyResource
    include Alba::Resource

    attributes :type, :id

    nested_attribute :attributes do
      attributes :name
    end

    nested_attribute :relationships do
      has_many :users, resource: UserResource
    end
  end

  # rubocop:disable Style/StringHashKeys
  def test_within_for_nested_attributes
    company = Company.new.tap do |c|
      c.id = 42
      c.name = 'a_new_company'
    end

    users = [
      User.new.tap do |u|
        u.id = 43
        u.full_name = 'a_new_user_0'
      end
    ]

    company.users = users
    users.each { |u| u.company = company }

    result1 = {
      'type' => 'companies',
      'id' => 42,
      'attributes' => {
        'name' => 'a_new_company'
      },
      'relationships' => {
        'users' => [
          {
            'type' => 'users',
            'id' => 43,
            'attributes' => {
              'full_name' => 'a_new_user_0'
            },
            'relationships' => {}
          }
        ]
      }
    }
    assert_equal(
      result1,
      CompanyResource.new(company, within: [:users]).to_h
    )

    result2 = {
      'type' => 'companies',
      'id' => 42,
      'attributes' => {
        'name' => 'a_new_company'
      },
      'relationships' => {
        'users' => [
          {
            'type' => 'users',
            'id' => 43,
            'attributes' => {
              'full_name' => 'a_new_user_0'
            },
            'relationships' => {
              'company' => {
                'type' => 'companies',
                'id' => 42,
                'attributes' => {
                  'name' => 'a_new_company'
                },
                'relationships' => {}
              }
            }
          }
        ]
      }
    }

    assert_equal(
      result2,
      CompanyResource.new(company, within: {users: :company}).to_h
    )
  end
  # rubocop:enable Style/StringHashKeys
end
