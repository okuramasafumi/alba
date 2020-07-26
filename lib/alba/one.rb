module Alba
  # Representing one association
  class One
    def initialize(name:, resource: nil, &block)
      @name = name
      @resource = resource
      @block = block
      raise ArgumentError, 'resource or block is required' if @resource.nil? && @block.nil?
    end

    def to_hash(target)
      object = target.public_send(@name)
      @resource ||= resource_class
      @resource.new(object).to_hash
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
