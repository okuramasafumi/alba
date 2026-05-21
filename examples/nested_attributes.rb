# frozen_string_literal: true

begin
  require 'alba'
rescue LoadError
  require_relative '../lib/alba'
end

class User
  attr_reader :id, :city, :zipcode, :card_brand, :last4

  def initialize(id, city, zipcode, card_brand, last4)
    @id = id
    @city = city
    @zipcode = zipcode
    @card_brand = card_brand
    @last4 = last4
  end
end

class UserResource
  include Alba::Resource

  root_key :user

  attributes :id

  nested :address do
    attributes :city, :zipcode
  end

  nested :billing do
    nested :card do
      attributes :card_brand, :last4
    end
  end
end

user = User.new(1, 'Tokyo', '100-0001', 'Visa', '4242')
puts UserResource.new(user).serialize
