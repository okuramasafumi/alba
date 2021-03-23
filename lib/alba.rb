require_relative 'alba/version'
require_relative 'alba/serializer'
require_relative 'alba/resource'
require_relative 'alba/null_cache_store'

# Core module
module Alba
  # Base class for Errors
  class Error < StandardError; end

  # Error class for backend which is not supported
  class UnsupportedBackend < Error; end

  class << self
    attr_reader :backend, :encoder, :cache, :cache_store
    attr_accessor :default_serializer

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

    # Set cache_store
    #
    # @params [Symbol] cache_store
    # @raise [Alba::Error] if active_support is not installed or given cache_store is not supported
    def cache_store=(cache_store = nil)
      @cache_store = cache_store
      @cache = NullCacheStore.new and return if cache_store.nil?

      begin
        require 'active_support/cache'
      rescue LoadError
        raise ::Alba::Error, 'To set cache_store, you must bundle `active_support` gem.'
      end

      cache_store_class = case cache_store.to_sym
                          when :memory then ActiveSupport::Cache::MemoryStore
                          when :redis then ActiveSupport::Cache::RedisStore
                          else
                            raise ::Alba::Error, "Unsupported cache_store: #{cache_store}. :memory and :redis are supported."
                          end
      @cache = cache_store_class.new
    end

    # Serialize the object with inline definitions
    #
    # @param object [Object] the object to be serialized
    # @param with [nil, Proc, Alba::Serializer] selializer
    # @param block [Block] resource block
    # @return [String] serialized JSON string
    # @raise [ArgumentError] if block is absent or `with` argument's type is wrong
    def serialize(object, with: nil, &block)
      raise ArgumentError, 'Block required' unless block

      resource_class.class_eval(&block)
      resource = resource_class.new(object)
      with ||= @default_serializer
      resource.serialize(with: with)
    end

    # Low level API to disable cache temporarily.
    #
    # @params [Block]
    def without_cache(&block)
      original_cache_store = Alba.cache_store
      raise ArgumentError, 'Block is required' unless block

      Alba.cache_store = nil
      yield
    ensure
      Alba.cache_store = original_cache_store
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
  @cache = NullCacheStore.new
end
