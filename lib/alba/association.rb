module Alba
  # Representing association
  class Association
    @const_cache = {}
    class << self
      attr_reader :const_cache
    end

    attr_reader :object, :name

    # @param name [Symbol, String] name of the method to fetch association
    # @param condition [Proc, nil] a proc filtering data
    # @param resource [Class<Alba::Resource>, nil] a resource class for the association
    # @param nesting [String] a namespace where source class is inferred with
    # @param block [Block] used to define resource when resource arg is absent
    def initialize(name:, condition: nil, resource: nil, nesting: nil, &block)
      @name = name
      @condition = condition
      @resource = resource
      return if @resource

      assign_resource(nesting, block)
    end

    # Recursively converts an object into a Hash
    #
    # @param target [Object] the object having an association method
    # @param within [Hash] determines what associations to be serialized. If not set, it serializes all associations.
    # @param params [Hash] user-given Hash for arbitrary data
    # @return [Hash]
    def to_h(target, within: nil, params: {})
      @object = target.public_send(@name)
      @object = @condition.call(object, params) if @condition
      return if @object.nil?

      @resource = constantize(@resource)
      @resource.new(object, params: params, within: within).to_h
    end

    private

    def constantize(resource)
      case resource # rubocop:disable Style/MissingElse
      when Class
        resource
      when Symbol, String
        self.class.const_cache.fetch(resource) do
          self.class.const_cache[resource] = Object.const_get(resource)
        end
      end
    end

    def assign_resource(nesting, block)
      @resource = if block
                    Alba.resource_class(&block)
                  elsif Alba.inferring
                    Alba.infer_resource_class(@name, nesting: nesting)
                  else
                    raise ArgumentError, 'When Alba.inferring is false, either resource or block is required'
                  end
    end
  end
end
