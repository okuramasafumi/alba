module Alba
  # Base class for `One` and `Many`
  # Child class should implement `to_hash` method
  class Association
    # @param name [Symbol] name of the method to fetch association
    # @param condition [Proc] a proc filtering data
    # @param resource [Class<Alba::Resource>] a resource class for the association
    # @param block [Block] used to define resource when resource arg is absent
    def initialize(name:, condition: nil, resource: nil, nesting: nil, &block)
      @name = name
      @condition = condition
      @block = block
      @resource = resource
      return if @resource

      if @block
        @resource = resource_class
      elsif Alba.with_inference
        const_parent = nesting.nil? ? Object : Object.const_get(nesting)
        @resource = const_parent.const_get("#{ActiveSupport::Inflector.classify(@name)}Resource")
      else
        raise ArgumentError, 'When Alba.with_inference is false, either resource or block is required'
      end
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
