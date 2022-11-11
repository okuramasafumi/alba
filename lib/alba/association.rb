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
    # @param params [Hash] params override for the association
    # @param nesting [String] a namespace where source class is inferred with
    # @param key_transformation [Symbol] key transformation type
    # @param block [Block] used to define resource when resource arg is absent
    def initialize(name:, condition: nil, resource: nil, params: {}, nesting: nil, key_transformation: :none, &block)
      @name = name
      @condition = condition
      @resource = resource
      @params = params
      return if @resource

      assign_resource(nesting, key_transformation, block)
    end

    # Recursively converts an object into a Hash
    #
    # @param target [Object] the object having an association method
    # @param within [Hash] determines what associations to be serialized. If not set, it serializes all associations.
    # @param params [Hash] user-given Hash for arbitrary data
    # @return [Hash]
    def to_h(target, within: nil, params: {})
      params = params.merge(@params) unless @params.empty?
      @object = target.__send__(@name)
      @object = @condition.call(object, params, target) if @condition
      return if @object.nil?

      if @resource.is_a?(Proc) && @object.is_a?(Enumerable)
        to_h_with_each_resource(within, params)
      else
        to_h_with_constantize_resource(within, params)
      end
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

    def assign_resource(nesting, key_transformation, block)
      @resource = if block
                    klass = Alba.resource_class
                    klass.transform_keys(key_transformation)
                    klass.class_eval(&block)
                    klass
                  elsif Alba.inflector
                    Alba.infer_resource_class(@name, nesting: nesting)
                  else
                    raise ArgumentError, 'When Alba.inflector is nil, either resource or block is required'
                  end
    end

    def to_h_with_each_resource(within, params)
      @object.map do |item|
        @resource.call(item).new(item, within: within, params: params).to_h
      end
    end

    def to_h_with_constantize_resource(within, params)
      @resource = constantize(@resource)
      @resource.new(object, params: params, within: within).to_h
    end
  end
end
