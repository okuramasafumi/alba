module Alba
  # This module represents how a resource should be serialized.
  module Serializer
    def self.included(base)
      base.include InstanceMethods
      base.extend ClassMethods
    end

    # Instance methods
    module InstanceMethods
      def initialize(resource)
        @_opts = self.class._opts || {}
        @_metadata = self.class._metadata || {}
        @_metadata = @_metadata.transform_values { |block| block.call(resource._object) }
        key = case @_opts[:key]
              when true
                resource.key
              else
                @_opts[:key]
              end
        @hash = resource.serializable_hash(with_key: false)
        @hash = {key.to_sym => @hash} if key
        # @hash is either Hash or Array
        @hash.is_a?(Hash) ? @hash.merge!(@_metadata.to_h) : @hash << @_metadata
      end

      def serialize
        Alba.encoder.call(@hash)
      end
    end

    # Class methods
    module ClassMethods
      attr_reader :_opts, :_metadata

      def inherited(subclass)
        %w[_opts _metadata].each { |name| subclass.instance_variable_set("@#{name}", instance_variable_get("@#{name}")) }
      end

      def set(key: false)
        @_opts ||= {}
        @_opts[:key] = key
      end

      def metadata(name, &block)
        @_metadata ||= {}
        @_metadata[name] = block
      end
    end
  end
end
