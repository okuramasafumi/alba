require_relative 'one'
require_relative 'many'

module Alba
  # This module represents what should be serialized
  module Resource
    # @!parse include InstanceMethods
    # @!parse extend ClassMethods
    DSLS = {_attributes: {}, _key: nil, _transform_keys: nil, _on_error: nil}.freeze
    private_constant :DSLS

    # @private
    def self.included(base)
      super
      base.class_eval do
        # Initialize
        DSLS.each do |name, initial|
          instance_variable_set("@#{name}", initial.dup) unless instance_variable_defined?("@#{name}")
        end
      end
      base.include InstanceMethods
      base.extend ClassMethods
    end

    # Instance methods
    module InstanceMethods
      attr_reader :object, :params

      # @param object [Object] the object to be serialized
      # @param params [Hash] user-given Hash for arbitrary data
      def initialize(object, params: {})
        @object = object
        @params = params.freeze
        DSLS.each_key { |name| instance_variable_set("@#{name}", self.class.public_send(name)) }
      end

      # Serialize object into JSON string
      #
      # @param key [Symbol]
      # @return [String] serialized JSON string
      def serialize(key: nil)
        key = key.nil? ? _key : key
        hash = key && key != '' ? {key.to_s => serializable_hash} : serializable_hash
        Alba.encoder.call(hash)
      end

      # A Hash for serialization
      #
      # @return [Hash]
      def serializable_hash
        collection? ? @object.map(&converter) : converter.call(@object)
      end
      alias to_hash serializable_hash

      private

      # @return [String]
      def _key
        if @_key == true && Alba.inferring
          demodulized = ActiveSupport::Inflector.demodulize(self.class.name)
          meth = collection? ? :tableize : :singularize
          ActiveSupport::Inflector.public_send(meth, demodulized.delete_suffix('Resource').downcase)
        else
          @_key.to_s
        end
      end

      def converter
        lambda do |resource|
          arrays = @_attributes.map do |key, attribute|
            key = transform_key(key)
            if attribute.is_a?(Array) # Conditional
              conditional_attribute(resource, key, attribute)
            else
              [key, fetch_attribute(resource, attribute)]
            end
          rescue ::Alba::Error, FrozenError
            raise
          rescue StandardError => e
            handle_error(e, resource, key, attribute)
          end
          arrays.reject(&:empty?).to_h
        end
      end

      def conditional_attribute(resource, key, attribute)
        fetched_attribute = fetch_attribute(resource, attribute.first)
        condition = attribute.last
        object = if attribute.first.is_a?(Alba::Association)
                   attribute.first.object
                 else
                   fetched_attribute
                 end
        if condition.respond_to?(:call) && condition.call(resource, object)
          [key, fetched_attribute]
        else
          []
        end
      end

      def handle_error(error, resource, key, attribute)
        on_error = @_on_error || Alba._on_error
        case on_error
        when :raise, nil
          raise
        when :nullify
          [key, nil]
        when :ignore
          []
        when Proc
          on_error.call(error, resource, key, attribute, self.class)
        else
          raise ::Alba::Error, "Unknown on_error: #{on_error.inspect}"
        end
      end

      # Override this method to supply custom key transform method
      def transform_key(key)
        return key unless @_transform_keys

        require_relative 'key_transformer'
        KeyTransformer.transform(key, @_transform_keys)
      end

      def fetch_attribute(resource, attribute)
        case attribute
        when Symbol
          resource.public_send attribute
        when Proc
          instance_exec(resource, &attribute)
        when Alba::One, Alba::Many
          attribute.to_hash(resource, params: params)
        else
          raise ::Alba::Error, "Unsupported type of attribute: #{attribute.class}"
        end
      end

      def collection?
        @object.is_a?(Enumerable)
      end
    end

    # Class methods
    module ClassMethods
      attr_reader(*DSLS.keys)

      # @private
      def inherited(subclass)
        super
        DSLS.each_key { |name| subclass.instance_variable_set("@#{name}", instance_variable_get("@#{name}").clone) }
      end

      # Set multiple attributes at once
      #
      # @param attrs [Array<String, Symbol>]
      # @param options [Hash] option hash including `if` that is a  condition to render these attributes
      def attributes(*attrs, **options)
        attrs.each do |attr_name|
          attr = options[:if] ? [attr_name.to_sym, options[:if]] : attr_name.to_sym
          @_attributes[attr_name.to_sym] = attr
        end
      end

      # Set an attribute with the given block
      #
      # @param name [String, Symbol] key name
      # @param options [Hash] option hash including `if` that is a  condition to render
      # @param block [Block] the block called during serialization
      # @raise [ArgumentError] if block is absent
      def attribute(name, **options, &block)
        raise ArgumentError, 'No block given in attribute method' unless block

        @_attributes[name.to_sym] = options[:if] ? [block, options[:if]] : block
      end

      # Set One association
      #
      # @param name [String, Symbol]
      # @param condition [Proc]
      # @param resource [Class<Alba::Resource>]
      # @param key [String, Symbol] used as key when given
      # @param options [Hash] option hash including `if` that is a  condition to render
      # @param block [Block]
      # @see Alba::One#initialize
      def one(name, condition = nil, resource: nil, key: nil, **options, &block)
        nesting = self.name&.rpartition('::')&.first
        one = One.new(name: name, condition: condition, resource: resource, nesting: nesting, &block)
        @_attributes[key&.to_sym || name.to_sym] = options[:if] ? [one, options[:if]] : one
      end
      alias has_one one

      # Set Many association
      #
      # @param name [String, Symbol]
      # @param condition [Proc]
      # @param resource [Class<Alba::Resource>]
      # @param key [String, Symbol] used as key when given
      # @param options [Hash] option hash including `if` that is a  condition to render
      # @param block [Block]
      # @see Alba::Many#initialize
      def many(name, condition = nil, resource: nil, key: nil, **options, &block)
        nesting = self.name&.rpartition('::')&.first
        many = Many.new(name: name, condition: condition, resource: resource, nesting: nesting, &block)
        @_attributes[key&.to_sym || name.to_sym] = options[:if] ? [many, options[:if]] : many
      end
      alias has_many many

      # Set key
      #
      # @param key [String, Symbol]
      def key(key)
        @_key = key.respond_to?(:to_sym) ? key.to_sym : key
      end

      # Set key to true
      #
      def key!
        @_key = true
      end

      # Delete attributes
      # Use this DSL in child class to ignore certain attributes
      #
      # @param attributes [Array<String, Symbol>]
      def ignoring(*attributes)
        attributes.each do |attr_name|
          @_attributes.delete(attr_name.to_sym)
        end
      end

      # Transform keys as specified type
      #
      # @param type [String, Symbol]
      def transform_keys(type)
        @_transform_keys = type.to_sym
      end

      # Set error handler
      #
      # @param [Symbol] handler
      # @param [Block]
      def on_error(handler = nil, &block)
        raise ArgumentError, 'You cannot specify error handler with both Symbol and block' if handler && block
        raise ArgumentError, 'You must specify error handler with either Symbol or block' unless handler || block

        @_on_error = handler || block
      end
    end
  end
end
