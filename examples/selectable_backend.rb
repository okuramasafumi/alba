# frozen_string_literal: true

begin
  require 'alba'
rescue LoadError
  require_relative '../lib/alba'
end
require 'json'

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

user = User.new(1, 'Masafumi')

Alba.backend = :json
puts UserResource.new(user).serialize

Alba.encoder = ->(object) { JSON.generate(object) }
puts UserResource.new(user).serialize
