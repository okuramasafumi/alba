# frozen_string_literal: true

begin
  require 'alba'
rescue LoadError
  require_relative '../lib/alba'
end

class Post
  attr_reader :title

  def initialize(title)
    @title = title
  end
end

class User
  attr_reader :id, :name, :email, :posts

  def initialize(id, name, email, posts = [])
    @id = id
    @name = name
    @email = email
    @posts = posts
  end
end

class UserResource
  include Alba::Resource

  attributes :id, :name, :email, if: ->(_user, value) { !value.nil? }

  many :posts, if: ->(_user) { params[:include_posts] } do
    attributes :title
  end
end

user = User.new(1, 'Ada', nil, [Post.new('Hello'), Post.new('World')])

puts UserResource.new(user, params: {include_posts: true}).serialize
puts UserResource.new(user, params: {include_posts: false}).serialize
