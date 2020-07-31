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
        key = case @_opts[:key]
              when true
                resource.key
              else
                @_opts[:key]
              end
        @hash = resource.serializable_hash(with_key: false)
        @hash = {key.to_sym => @hash} if key
      end

      def serialize
        fallback = lambda do
          require 'json'
          JSON.dump(@hash)
        end
        case Alba.backend
        when :oj
          begin
            require 'oj'
            -> { Oj.dump(@hash, mode: :strict) }
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
