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

  attributes :id, :name
end

user = User.new(1, 'No Extra Gems')

# Uses Ruby's standard JSON encoder by default (no extra runtime gem required).
puts UserResource.new(user).serialize
