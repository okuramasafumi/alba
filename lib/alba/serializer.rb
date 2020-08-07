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
        @resource = resource
        @hash = resource.serializable_hash
        @hash = {key.to_sym => @hash} if key
        # @hash is either Hash or Array
        @hash.is_a?(Hash) ? @hash.merge!(metadata.to_h) : @hash << metadata
      end

      def serialize
        Alba.encoder.call(@hash)
      end

      private

      def key
        opts = self.class._opts || {}
        case opts[:key]
        when true
          @resource.key
        else
          opts[:key]
        end
      end

      def metadata
        metadata = self.class._metadata || {}
        metadata.transform_values { |block| block.call(@resource._object) }
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
