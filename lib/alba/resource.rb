require 'alba/serializer'
require 'alba/attribute'
require 'alba/many'
require 'alba/serializers/default_serializer'

module Alba
  # This module represents what should be serialized
  module Resource
    def self.included(base)
      base.include InstanceMethods
      base.extend ClassMethods
    end

    # Instance methods
    module InstanceMethods
      def initialize(resource)
        @_resource = resource
        @_attributes = self.class._attributes
        @_many = self.class._many
        @_serializer_class = self.class._serializer_class
      end

      def serialize(with: nil)
        serializer_class = case with
                           when ->(obj) { obj.is_a?(Class) && obj.ancestors.include?(Alba::Serializer) }
                             with
                           when Symbol
                             const_get(with.to_s.capitalize)
                           when String
                             const_get(with)
                           when nil
                             @_serializer_class || Alba::Serializers::DefaultSerializer
                           end
        serializer_class.new(serializable_hash).serialize
      end

      def to_hash
        serializable_hash
      end

      private

      def serializable_hash
        attrs = @_attributes&.transform_values do |attribute|
          attribute.serialize(@_resource)
        end || {}
        manies = @_many&.transform_values do |many|
          many.to_hash(@_resource)
        end || {}
        attrs.merge(manies)
      end
    end

    # Class methods
    module ClassMethods
      attr_accessor :_attributes, :_serializer_class, :_many

      def inherited(subclass)
        @_attributes = {} unless defined?(@_attributes)
        @_many = {} unless defined? @_many
        @_serializer_class = nil unless defined?(@_serializer_class)
        subclass._attributes = @_attributes
        subclass._many = @_many
        subclass._serializer_class = @_serializer_class
      end

      def attributes(*attrs)
        @_attributes = {} unless defined? @_attributes
        attrs.each { |attr_name| @_attributes[attr_name] = Attribute.new(name: attr_name, method: attr_name) }
      end

      def attribute(name, &block)
        @_attributes = {} unless defined? @_attributes
        raise ArgumentError, 'No block given in attribute method' unless block

        @_attributes[name] = Attribute.new(name: name, method: block)
      end

      def many(name, resource: nil, &block)
        @_many = {} unless defined? @_many
        @_many[name.to_sym] = Many.new(name: name, resource: resource, &block)
      end

      def serializer(name)
        @_serializer_class = name.ancestors.include?(Alba::Serializer) ? name : nil
      end
    end
  end
end
