module Alba
  # Base class for `One` and `Many`
  # Child class should implement `to_hash` method
  class Association
    def initialize(name:, resource: nil, &block)
      @name = name
      @resource = resource
      @block = block
      raise ArgumentError, 'resource or block is required' if @resource.nil? && @block.nil?
    end

    def to_hash
      :not_implemented
    end

    private

    def resource_class
      klass = Class.new
      klass.include(::Alba::Resource)
      klass.class_exec(&@block)
      klass
    end
  end
end
