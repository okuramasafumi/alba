module Alba
  # This module represents how a resource should be serialized.
  module Serializer
    # @!parse include InstanceMethods
    # @!parse extend ClassMethods

    # @private
    def self.included(base)
      super
      base.instance_variable_set('@_opts', {}) unless base.instance_variable_defined?('@_opts')
      base.instance_variable_set('@_metadata', {}) unless base.instance_variable_defined?('@_metadata')
      base.include InstanceMethods
      base.extend ClassMethods
    end

    # Instance methods
    module InstanceMethods
      # @param resource [Alba::Resource]
      def initialize(resource)
        @resource = resource
        @hash = resource.serializable_hash
        @hash = {key.to_sym => @hash} if key
        return if metadata.empty?

        # @hash is either Hash or Array
        @hash.is_a?(Hash) ? @hash.merge!(metadata.to_h) : @hash << metadata
      end

      # Use real encoder to actually serialize to JSON
      #
      # @return [String] JSON string
      def serialize
        Alba.encoder.call(@hash)
      end

      private

      def key
        opts = self.class._opts
        opts[:key] == true ? @resource.key : opts[:key]
      end

      def metadata
        metadata = self.class._metadata
        metadata.transform_values { |block| block.call(@resource.object) }
      end
    end

    # Class methods
    module ClassMethods
      attr_reader :_opts, :_metadata

      # @private
      def inherited(subclass)
        super
        %w[_opts _metadata].each { |name| subclass.instance_variable_set("@#{name}", public_send(name).clone) }
      end

      # Set options, currently key only
      #
      # @param key [Boolean, Symbol]
      def set(key: false)
        @_opts[:key] = key
      end

      # Set metadata
      #
      # @param name [String, Symbol] key for the metadata
      # @param block [Block] the content of the metadata
      def metadata(name, &block)
        @_metadata[name.to_sym] = block
      end
    end
  end
end
