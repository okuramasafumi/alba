require 'alba/version'
require 'alba/resource'
require 'json'

# Core module
module Alba
  class Error < StandardError; end

  class << self
    attr_reader :backend
  end

  def self.backend=(backend)
    @backend = backend&.to_sym
  end

  def self.serialize(object)
    Serializers::DefaultSerializer.new(object).serialize
  end
end
