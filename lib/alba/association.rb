# frozen_string_literal: true

module Alba
  # Representing association
  # @api private
  class Association
    @const_cache = {}
    class << self
      # cache for `const_get`
      attr_reader :const_cache
    end

    attr_reader :name

    # @param name [Symbol, String] name of the method to fetch association
    # @param condition [Proc, nil] a proc filtering data
    # @param resource [Class<Alba::Resource>, Proc, String, Symbol, nil]
    #   a resource class for the association, a proc returning a resource class or a name of the resource
    # @param source [Proc, nil] a proc to specify the source of the association
    # @param with_traits [Symbol, Array<Symbol>, nil] specified traits
    # @param params [Hash] params override for the association
    # @param nesting [String] a namespace where source class is inferred with
    # @param key_transformation [Symbol] key transformation type
    # @param helper [Module] helper module to include
    # @param block [Block] used to define resource when resource arg is absent
    def initialize(
      name:,
      condition: nil,
      resource: nil,
      source: nil,
      with_traits: nil,
      params: {},
      nesting: nil,
      key_transformation: :none,
      helper: nil,
      &block
    )
      @name = name
      @condition = condition
      @resource = resource
      @source = source
      @with_traits = with_traits
      @params = params
      return if @resource

      assign_resource(nesting, key_transformation, block, helper)
    end

    # This is the same API in `NestedAttribute`
    #
    # @param type [String, Symbol] one of `snake`, `:camel`, `:lower_camel`, `:dash` and `none`
    # @return [void]
    def key_transformation=(type)
      @resource.transform_keys(type) unless @resource.is_a?(Proc)
    end

    # Recursively converts an object into a Hash
    #
    # @param target [Object] the object having an association method
    # @param within [Hash] determines what associations to be serialized. If not set, it serializes all associations.
    # @param params [Hash] user-given Hash for arbitrary data
    # @return [Hash]
    def to_h(target, within: nil, params: {})
      params = params.merge(@params)
      object = object_from(target, params)
      return if object.nil?

      if @resource.is_a?(Proc)
        return to_h_with_each_resource(object, within, params) if object.is_a?(Enumerable)

        @resource.call(object).new(object, within: within, params: params, with_traits: @with_traits).to_h
      else
        to_h_with_constantize_resource(object, within, params)
      end
    end

    private

    def object_from(target, params)
      o = if @source
            target.instance_exec(params, &@source)
          else
            target.is_a?(Hash) ? target.fetch(@name) : target.__send__(@name)
          end
      o = @condition.call(o, params, target) if @condition
      o
    end

    def constantize(resource)
      case resource
      when Class
        resource
      when Symbol, String
        self.class.const_cache.fetch(resource) do
          self.class.const_cache[resource] = Object.const_get(resource)
        end
      else
        raise Error, "Unexpected resource type: #{resource.class}"
      end
    end

    def assign_resource(nesting, key_transformation, block, helper)
      @resource = if block
                    charged_resource_class(helper, key_transformation, block)
                  elsif Alba.inflector
                    Alba.infer_resource_class(@name, nesting: nesting)
                  else
                    raise ArgumentError, 'When Alba.inflector is nil, either resource or block is required'
                  end
    end

    def charged_resource_class(helper, key_transformation, block)
      klass = Alba.resource_class
      klass.helper(helper) if helper
      klass.transform_keys(key_transformation)
      klass.class_eval(&block)
      klass
    end

    def to_h_with_each_resource(object, within, params)
      object.map do |item|
        @resource.call(item).new(item, within: within, params: params, with_traits: @with_traits).to_h
      end
    end

    def to_h_with_constantize_resource(object, within, params)
      @resource = constantize(@resource)
      @resource.new(object, params: params, within: within, with_traits: @with_traits).to_h
    end
  end
end
