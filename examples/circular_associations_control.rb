# frozen_string_literal: true

begin
  require 'alba'
rescue LoadError
  require_relative '../lib/alba'
end

class Author
  attr_accessor :name, :books

  def initialize(name, books = [])
    @name = name
    @books = books
  end
end

class Book
  attr_accessor :title, :authors

  def initialize(title, authors = [])
    @title = title
    @authors = authors
  end
end

class AuthorResource
  include Alba::Resource

  root_key :author, :authors
  attributes :name
  many :books, resource: 'BookResource'
end

class BookResource
  include Alba::Resource

  root_key :book, :books
  attributes :title
  many :authors, resource: 'AuthorResource'
end

book = Book.new('Alba 101')
author = Author.new('Ada')

book.authors = [author]
author.books = [book]

puts BookResource.new(book, within: {authors: :books}).serialize
puts AuthorResource.new(author, within: {books: :authors}).serialize
