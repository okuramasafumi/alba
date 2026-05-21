# frozen_string_literal: true

begin
  require 'alba'
rescue LoadError
  require_relative '../lib/alba'
end

class Article
  attr_reader :title, :body

  def initialize(title, body)
    @title = title
    @body = body
  end
end

class User
  attr_reader :id, :articles

  def initialize(id, articles)
    @id = id
    @articles = articles
  end
end

user = User.new(1, [Article.new('Hello World!', 'Hello World!!!'), Article.new('Super nice', 'Really nice!')])

json = Alba.serialize(user) do
  root_key(:user)
  attributes(:id)

  many(:articles) do
    attributes(:title, :body)
  end
end

puts json

hash = Alba.hashify(user) do
  attributes(:id)
end

puts hash
