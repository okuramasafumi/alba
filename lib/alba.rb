require_relative 'alba/version'
require_relative 'alba/resource'

# Core module
module Alba
  # Base class for Errors
  class Error < StandardError; end

  # Error class for backend which is not supported
  class UnsupportedBackend < Error; end

  class << self
    attr_reader :backend, :encoder

    # Set the backend, which actually serializes object into JSON
    #
    # @param backend [#to_sym, nil] the name of the backend
    #   Possible values are `oj`, `active_support`, `default`, `json` and nil
    # @return [Proc] the proc to encode object into JSON
    # @raise [Alba::UnsupportedBackend] if backend is not supported
    def backend=(backend)
      @backend = backend&.to_sym
      set_encoder
    end

    # Serialize the object with inline definitions
    #
    # @param object [Object] the object to be serialized
    # @param key [Symbol]
    # @param block [Block] resource block
    # @return [String] serialized JSON string
    # @raise [ArgumentError] if block is absent or `with` argument's type is wrong
    def serialize(object, key: nil, &block)
      raise ArgumentError, 'Block required' unless block

      resource_class.class_eval(&block)
      resource = resource_class.new(object)
      resource.serialize(key: key)
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
                   raise Alba::UnsupportedBackend, "Unsupported backend, #{backend}"
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
      @resource_class ||= begin
        klass = Class.new
        klass.include(Alba::Resource)
      end
    end
  end

  @encoder = default_encoder
end
