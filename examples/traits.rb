# frozen_string_literal: true

begin
  require 'alba'
rescue LoadError
  require_relative '../lib/alba'
end

class Profile
  attr_reader :display_name, :status

  def initialize(display_name, status)
    @display_name = display_name
    @status = status
  end
end

class User
  attr_reader :id, :name, :email, :profile

  def initialize(id, name, email, profile)
    @id = id
    @name = name
    @email = email
    @profile = profile
  end
end

class ProfileResource
  include Alba::Resource

  attributes :display_name

  trait :with_status do
    attributes :status
  end
end

class UserResource
  include Alba::Resource

  attributes :id

  trait :public do
    attributes :name
  end

  trait :private do
    attributes :email
  end

  trait :with_profile do
    one :profile, resource: ProfileResource, with_traits: :with_status
  end
end

user = User.new(1, 'Masa', 'masa@example.com', Profile.new('Masa O.', 'active'))

puts UserResource.new(user).serialize
puts UserResource.new(user, with_traits: :public).serialize
puts UserResource.new(user, with_traits: %i[public private with_profile]).serialize
