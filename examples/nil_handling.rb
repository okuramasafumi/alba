# frozen_string_literal: true

begin
  require 'alba'
rescue LoadError
  require_relative '../lib/alba'
end

class User
  attr_reader :id, :name, :age

  def initialize(id, name = nil, age = nil)
    @id = id
    @name = name
    @age = age
  end
end

class UserResource
  include Alba::Resource

  root_key :user
  attributes :id, :name, :age

  on_nil do |object, key|
    key == 'age' ? 20 : "User#{object.id}"
  end
end

user = User.new(1)
puts UserResource.new(user).serialize
