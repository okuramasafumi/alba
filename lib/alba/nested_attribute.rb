# frozen_string_literal: true

module Alba
  # Representing nested attribute
  # @api private
  class NestedAttribute
    # Setter for key_transformation, used when it's changed after class definition
    attr_writer :key_transformation

    # @param key_transformation [Symbol] determines how to transform keys
    # @param block [Proc] class body
    def initialize(key_transformation: :none, &block)
      @key_transformation = key_transformation
      @block = block
    end

    # @param object [Object] the object being serialized
    # @param params [Hash] params Hash inherited from Resource
    # @param within [Object, nil, false, true] determines what associations to be serialized. If not set, it serializes all associations.
    # @param select [Method] select method object from its origin
    # @return [Hash] hash serialized from running the class body in the object
    def value(object:, params:, within:, select: nil)
      resource_class = Alba.resource_class
      resource_class.transform_keys(@key_transformation)
      resource_class.class_eval(&@block)
      resource_class.new(object, params: params, within: within, select: select).serializable_hash
    end
  end
end
