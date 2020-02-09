module Alba
  # This module represents how a resource should be serialized.
  #
  module Serializer
    def self.included(base)
      base.include InstanceMethods
      base.extend ClassMethods
    end

    # Instance methods
    module InstanceMethods
      def initialize(resource)
        @_resource = resource
        @_opts = self.class._opts || {}
        key = @_opts[:key]
        @_resource = {key.to_sym => @_resource} if key
      end

      def serialize
        fallback = -> { @_resource.to_json }
        case Alba.backend
        when :oj
          begin
            require 'oj'
            -> { Oj.dump(@_resource) }
          rescue LoadError
            fallback
          end
        else
          fallback
        end.call
      end
    end

    # Class methods
    module ClassMethods
      attr_reader :_opts

      def set(key: false)
        @_opts ||= {}
        @_opts[:key] = key
      end
    end
  end
end
