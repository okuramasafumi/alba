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

class PaginatedUsers
  attr_reader :items, :page, :per_page, :total

  def initialize(items, page:, per_page:, total:)
    @items = items
    @page = page
    @per_page = per_page
    @total = total
  end

  def total_pages
    (Float(total) / per_page).ceil
  end
end

class UserResource
  include Alba::Resource

  attributes :id, :name
end

class PaginatedUsersResource
  include Alba::Resource

  root_key :result

  many :items, key: :users, resource: UserResource

  meta :pagination do
    {
      page: object.page,
      per_page: object.per_page,
      total: object.total,
      total_pages: object.total_pages
    }
  end
end

page = PaginatedUsers.new([User.new(1, 'John'), User.new(2, 'Masafumi')], page: 1, per_page: 2, total: 5)

puts PaginatedUsersResource.new(page).serialize
