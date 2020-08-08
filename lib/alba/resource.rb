require 'alba/serializer'
require 'alba/one'
require 'alba/many'
require 'alba/serializers/default_serializer'

module Alba
  # This module represents what should be serialized
  module Resource
    DSLS = [:_attributes, :_serializer, :_key].freeze
    def self.included(base)
      base.class_eval do
        # Initialize
        DSLS.each do |name|
          initial = case name
                    when :_attributes
                      {}
                    when :_serializer, :_name
                      nil
                    end
          instance_variable_set("@#{name}", initial) unless instance_variable_defined?("@#{name}")
        end
      end
      base.include InstanceMethods
      base.extend ClassMethods
    end

    # Instance methods
    module InstanceMethods
      attr_reader :_object, :_key, :params

      def initialize(object, params: {})
        @_object = object
        @params = params
        DSLS.each { |name| instance_variable_set("@#{name}", self.class.public_send(name)) }
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
        get_attribute = lambda do |resource|
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
        if collection?
          @_object.map(&get_attribute)
        else
          get_attribute.call(@_object)
        end
      end
      alias to_hash serializable_hash

      def key
        @_key || self.class.name.delete_suffix('Resource').downcase.gsub(/:{2}/, '_').to_sym
      end

      private

      def inline_extended_serializer(with)
        klass = ::Alba::Serializers::DefaultSerializer.clone
        klass.class_eval(&with)
        klass
      end

      def collection?
        @_object.is_a?(Enumerable)
      end
    end

    # Class methods
    module ClassMethods
      attr_reader(*DSLS)

      def inherited(subclass)
        DSLS.each { |name| subclass.instance_variable_set("@#{name}", instance_variable_get("@#{name}")) }
      end

      def attributes(*attrs)
        attrs.each { |attr_name| @_attributes[attr_name] = attr_name }
      end

      def attribute(name, &block)
        raise ArgumentError, 'No block given in attribute method' unless block

        @_attributes[name] = block
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
    end
  end
end
