module Alba
  # Representing many association
  class Many
    def initialize(name:, resource: nil, &block)
      @name = name
      @resource = resource
      @block = block
      raise ArgumentError, 'resource or block is required' if @resource.nil? && @block.nil?
    end

    def to_hash(target)
      objects = target.__send__(@name)
      @resource ||= resource_class
      objects.map { |o| @resource.new(o).to_hash }
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
