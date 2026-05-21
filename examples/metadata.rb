# frozen_string_literal: true

begin
  require 'alba'
rescue LoadError
  require_relative '../lib/alba'
end

class User
  attr_reader :id, :name

  def initialize(id, name)
    @id = id
    @name = name
  end
end

class UserResource
  include Alba::Resource

  root_key :user, :users

  attributes :id, :name

  meta do
    {
      count: object.respond_to?(:size) ? object.size : 1,
      requested_by: params[:requested_by]
    }
  end
end

class UserResourceWithCustomMetaKey
  include Alba::Resource

  root_key :user, :users

  attributes :id, :name

  meta :pagination
end

users = [User.new(1, 'John'), User.new(2, 'Masafumi')]

puts UserResource.new(users, params: {requested_by: 'admin'}).serialize
puts UserResourceWithCustomMetaKey.new(users).serialize(meta: {page: 1, total_pages: 3})
