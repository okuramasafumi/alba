require 'alba/serializer'
require 'alba/one'
require 'alba/many'
require 'alba/serializers/default_serializer'

module Alba
  # This module represents what should be serialized
  module Resource
    DSLS = {_attributes: {}, _serializer: nil, _key: nil}.freeze
    def self.included(base)
      super
      base.class_eval do
        # Initialize
        DSLS.each do |name, initial|
          instance_variable_set("@#{name}", initial.dup) unless instance_variable_defined?("@#{name}")
        end
      end
      base.include InstanceMethods
      base.extend ClassMethods
    end

    # Instance methods
    module InstanceMethods
      attr_reader :object, :_key, :params

      def initialize(object, params: {})
        @object = object
        @params = params
        DSLS.each_key { |name| instance_variable_set("@#{name}", self.class.public_send(name)) }
      end

      def serialize(with: nil)
        serializer = case with
                     when nil
                       @_serializer || Alba::Serializers::DefaultSerializer
                     when ->(obj) { obj.is_a?(Class) && obj <= Alba::Serializer }
                       with
                     when Proc
                       inline_extended_serializer(with)
                     else
                       raise ArgumentError, 'Unexpected type for with, possible types are Class or Proc'
                     end
        serializer.new(self).serialize
      end

      def serializable_hash
        collection? ? @object.map(&converter) : converter.call(@object)
      end
      alias to_hash serializable_hash

      def key
        @_key || self.class.name.delete_suffix('Resource').downcase.gsub(/:{2}/, '_').to_sym
      end

      private

      def converter
        lambda do |resource|
          @_attributes.transform_values do |attribute|
            case attribute
            when Symbol
              resource.public_send attribute
            when Proc
              instance_exec(resource, &attribute)
            when Alba::One, Alba::Many
              attribute.to_hash(resource)
            end
          end
        end
      end

      def inline_extended_serializer(with)
        klass = ::Alba::Serializers::DefaultSerializer.clone
        klass.class_eval(&with)
        klass
      end

      def collection?
        @object.is_a?(Enumerable)
      end
    end

    # Class methods
    module ClassMethods
      attr_reader(*DSLS.keys)

      def inherited(subclass)
        super
        DSLS.each_key { |name| subclass.instance_variable_set("@#{name}", instance_variable_get("@#{name}").clone) }
      end

      def attributes(*attrs)
        attrs.each { |attr_name| @_attributes[attr_name.to_sym] = attr_name.to_sym }
      end

      def attribute(name, &block)
        raise ArgumentError, 'No block given in attribute method' unless block

        @_attributes[name.to_sym] = block
      end

      def one(name, resource: nil, &block)
        @_attributes[name.to_sym] = One.new(name: name, resource: resource, &block)
      end

      def many(name, resource: nil, &block)
        @_attributes[name.to_sym] = Many.new(name: name, resource: resource, &block)
      end

      def serializer(name)
        @_serializer = name <= Alba::Serializer ? name : nil
      end

      def key(key)
        @_key = key.to_sym
      end

      # Use this DSL in child class to ignore certain attributes
      def ignoring(*attributes)
        attributes.each do |attr_name|
          @_attributes.delete(attr_name.to_sym)
        end
      end
    end
  end
end
