module Alba
  # Representing nested attribute
  class NestedAttribute
    # @param block [Proc] class body
    def initialize(&block)
      @block = block
    end

    # @return [Hash]
    def value(object)
      resource_class = Alba.resource_class(&@block)
      resource_class.new(object).serializable_hash
    end
  end
end
