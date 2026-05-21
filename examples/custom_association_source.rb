# frozen_string_literal: true

begin
  require 'alba'
rescue LoadError
  require_relative '../lib/alba'
end

class Article
  attr_reader :title, :status

  def initialize(title, status)
    @title = title
    @status = status
  end
end

class User
  attr_reader :id, :name, :articles

  def initialize(id, name, articles)
    @id = id
    @name = name
    @articles = articles
    @metadata = {role: 'admin', department: 'engineering'}
  end

  def custom_profile
    {email: "#{name.downcase}@example.com", plan: 'pro'}
  end

  def articles_by_status(status)
    articles.select { |article| article.status == status }
  end
end

class MetadataResource
  include Alba::Resource

  attributes :role, :department
end

class ArticleResource
  include Alba::Resource

  attributes :title, :status
end

class UserResource
  include Alba::Resource

  attributes :id, :name

  one :profile, source: proc { custom_profile } do
    attributes :email, :plan
  end

  one :metadata, source: proc { @metadata }, resource: MetadataResource

  many :published_articles, source: proc { |params| articles_by_status(params.fetch(:status, 'published')) }, resource: ArticleResource
end

articles = [Article.new('Shipped', 'published'), Article.new('Draft notes', 'draft')]
user = User.new(1, 'Masa', articles)

puts UserResource.new(user).serialize
puts UserResource.new(user, params: {status: 'draft'}).serialize
