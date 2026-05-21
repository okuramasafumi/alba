# frozen_string_literal: true

begin
  require 'alba'
rescue LoadError
  require_relative '../lib/alba'
end

module ExampleInflector
  module_function

  def camelize(str)
    str = str.to_s
    str.split('_').map(&:capitalize).join
  end

  def camelize_lower(str)
    str = str.to_s
    parts = str.split('_')
    ([parts.first] + parts.drop(1).map(&:capitalize)).join
  end

  def dasherize(str)
    str.to_s.tr('_', '-')
  end

  def classify(str)
    str = str.to_s
    str = str.sub(/s\z/, '')
    camelize(str)
  end

  def demodulize(str)
    str.to_s.split('::').last
  end

  def underscore(str)
    str = str.to_s
    str.gsub('::', '/').gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2').gsub(/([a-z\d])([A-Z])/, '\1_\2').tr('-', '_').downcase
  end

  def pluralize(str)
    "#{str}s"
  end
end

Alba.inflector = ExampleInflector

class User
  attr_reader :id, :first_name, :last_name

  def initialize(id, first_name, last_name)
    @id = id
    @first_name = first_name
    @last_name = last_name
  end
end

class UserResource
  include Alba::Resource

  attributes :id, :first_name, :last_name
  transform_keys :lower_camel
end

user = User.new(1, 'Masafumi', 'Okura')
puts UserResource.new(user).serialize
