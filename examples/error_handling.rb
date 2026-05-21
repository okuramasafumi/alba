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

  def email
    raise 'Email fetch failed'
  end
end

class UserResource
  include Alba::Resource

  attributes :id, :name, :email
  on_error :ignore
end

user = User.new(1, 'Test')
puts UserResource.new(user).serialize
