module Alba
  # Base class for `One` and `Many`
  # Child class should implement `to_hash` method
  class Association
    def initialize(name:, resource: nil, &block)
      @name = name
      @block = block
      @resource = resource || resource_class
      raise ArgumentError, 'resource or block is required' if @resource.nil? && @block.nil?
    end

    def to_hash
      :not_implemented
    end

    private

    def resource_class
      klass = ::Alba::Resources::DefaultResource.dup
      klass.reset
      klass.class_eval(&@block)
      klass
    end
  end
end
