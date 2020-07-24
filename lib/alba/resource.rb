require 'alba/serializer'
require 'alba/attribute'
require 'alba/one'
require 'alba/many'
require 'alba/serializers/default_serializer'

module Alba
  # This module represents what should be serialized
  module Resource
    DSLS = [:_attributes, :_one, :_many, :_serializer].freeze
    def self.included(base)
      base.class_eval do
        # Initialize
        DSLS.each do |name|
          initial = name == :_serializer ? nil : {}
          instance_variable_set("@#{name}", initial) unless instance_variable_defined?("@#{name}")
        end
      end
      base.include InstanceMethods
      base.extend ClassMethods
    end

    # Instance methods
    module InstanceMethods
      def initialize(resource)
        @_resource = resource
        DSLS.each { |name| instance_variable_set("@#{name}", self.class.public_send(name)) }
      end

      def serialize(with: nil)
        serializer = case with
                     when ->(obj) { obj.is_a?(Class) && obj <= Alba::Serializer }
                       with
                     when Symbol
                       const_get(with.to_s.capitalize)
                     when String
                       const_get(with)
                     when nil
                       @_serializer || Alba::Serializers::DefaultSerializer
                     end
        serializer.new(serializable_hash).serialize
      end

      def serializable_hash
        attrs.merge(ones).merge(manies)
      end
      alias to_hash serializable_hash

      private

      def attrs
        @_attributes.transform_values do |attribute|
          attribute.to_hash(@_resource)
        end || {}
      end

      def ones
        @_one.transform_values do |one|
          one.to_hash(@_resource)
        end || {}
      end

      def manies
        @_many.transform_values do |many|
          many.to_hash(@_resource)
        end || {}
      end
    end

    # Class methods
    module ClassMethods
      attr_accessor(*DSLS)

      def inherited(subclass)
        DSLS.each { |name| subclass.public_send("#{name}=", instance_variable_get("@#{name}")) }
      end

      def attributes(*attrs)
        attrs.each { |attr_name| @_attributes[attr_name] = Attribute.new(name: attr_name, method: attr_name) }
      end

      def attribute(name, &block)
        raise ArgumentError, 'No block given in attribute method' unless block

        @_attributes[name] = Attribute.new(name: name, method: block)
      end

      def one(name, resource: nil, &block)
        @_one[name.to_sym] = One.new(name: name, resource: resource, &block)
      end

      def many(name, resource: nil, &block)
        @_many[name.to_sym] = Many.new(name: name, resource: resource, &block)
      end

      def serializer(name)
        @_serializer = name <= Alba::Serializer ? name : nil
      end
    end
  end
end
