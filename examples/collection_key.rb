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

  collection_key :id

  attributes :id, :name
end

users = [User.new(1, 'John'), User.new(2, 'Masafumi')]

puts UserResource.new(users).serialize
