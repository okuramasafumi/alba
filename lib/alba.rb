require 'alba/version'
require 'alba/serializers/default_serializer'
require 'alba/serializer'
require 'alba/resource'
require 'alba/resources/default_resource'

# Core module
module Alba
  class Error < StandardError; end

  class << self
    attr_reader :backend, :encoder
    attr_accessor :default_serializer

    def backend=(backend)
      @backend = backend&.to_sym
      set_encoder
    end

    def serialize(object, with: nil, &block)
      raise ArgumentError, 'Block required' unless block

      resource_class.class_eval(&block)
      resource = resource_class.new(object)
      with ||= @default_serializer
      resource.serialize(with: with)
    end

    private

    def set_encoder
      @encoder = case @backend
                 when :oj
                   try_oj
                 when :active_support
                   try_active_support
                 when nil, :default, :json
                   default_encoder
                 else
                   raise Alba::Error, "Unsupported backend, #{backend}"
                 end
    end

    def try_oj
      require 'oj'
      ->(hash) { Oj.dump(hash, mode: :strict) }
    rescue LoadError
      default_encoder
    end

    def try_active_support
      require 'active_support/json'
      ->(hash) { ActiveSupport::JSON.encode(hash) }
    rescue LoadError
      default_encoder
    end

    def default_encoder
      lambda do |hash|
        require 'json'
        JSON.dump(hash)
      end
    end

    def resource_class
      ::Alba::Resources::DefaultResource.clone
    end
  end

  @encoder = default_encoder
end
