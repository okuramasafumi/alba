# frozen_string_literal: true

begin
  require 'alba'
rescue LoadError
  require_relative '../lib/alba'
end

class Foo
  attr_reader :id

  def initialize(id)
    @id = id
  end
end

class FooResource
  include Alba::Resource

  attributes :id

  layout inline: proc {
    {
      header: params[:header],
      body: serializable_hash
    }
  }
end

foo = Foo.new(1)
puts FooResource.new(foo, params: {header: 'my_header'}).serialize
