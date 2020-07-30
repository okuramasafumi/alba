require 'alba/version'
require 'alba/serializers/default_serializer'
require 'alba/serializer'
require 'alba/resource'
require 'alba/resources/default_resource'

# Core module
module Alba
  class Error < StandardError; end

  class << self
    attr_reader :backend

    def backend=(backend)
      @backend = backend&.to_sym
    end

    def serialize(object, with: nil, &block)
      raise ArgumentError, 'Block required' unless block

      resource_class.class_eval(&block)
      resource = resource_class.new(object)
      resource.serialize(with: with)
    end

    private

    def resource_class
      ::Alba::Resources::DefaultResource.clone
    end
  end
end
