module Alba
  # Representing nested attribute
  class NestedAttribute
    # @param key_transformation [Symbol] determines how to transform keys
    # @param block [Proc] class body
    def initialize(key_transformation: :none, &block)
      @key_transformation = key_transformation
      @block = block
    end

    # @return [Hash]
    def value(object)
      resource_class = Alba.resource_class
      resource_class.transform_keys(@key_transformation)
      resource_class.class_eval(&@block)
      resource_class.new(object).serializable_hash
    end
  end
end
