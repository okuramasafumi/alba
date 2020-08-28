module Alba
  # Base class for `One` and `Many`
  # Child class should implement `to_hash` method
  class Association
    # @param name [Symbol] name of the method to fetch association
    # @param condition [Proc] a proc filtering data
    # @param resource [Class<Alba::Resource>] a resource class for the association
    # @param block [Block] used to define resource when resource arg is absent
    def initialize(name:, condition: nil, resource: nil, &block)
      @name = name
      @condition = condition
      @block = block
      @resource = resource || resource_class
      raise ArgumentError, 'resource or block is required' if @resource.nil? && @block.nil?
    end

    # @abstract
    def to_hash
      :not_implemented
    end

    private

    def resource_class
      klass = Class.new
      klass.include(Alba::Resource)
      klass.class_eval(&@block)
      klass
    end
  end
end
