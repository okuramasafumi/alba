require_relative 'one'
require_relative 'many'

module Alba
  # This module represents what should be serialized
  module Resource
    # @!parse include InstanceMethods
    # @!parse extend ClassMethods
    DSLS = {_attributes: {}, _key: nil, _transform_keys: nil, _transforming_root_key: false, _on_error: nil}.freeze
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
      # @param within [Hash] determines what associations to be serialized. If not set, it serializes all associations.
      def initialize(object, params: {}, within: true)
        @object = object
        @params = params.freeze
        @within = within
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
        return @_key.to_s unless @_key == true && Alba.inferring

        resource_name = self.class.name.demodulize.delete_suffix('Resource').underscore
        key = collection? ? resource_name.pluralize : resource_name
        transforming_root_key = @_transforming_root_key.nil? ? Alba.transforming_root_key : @_transforming_root_key
        transforming_root_key ? transform_key(key) : key
      end

      def converter
        lambda do |object|
          arrays = @_attributes.map do |key, attribute|
            key = transform_key(key)
            if attribute.is_a?(Array) # Conditional
              conditional_attribute(object, key, attribute)
            else
              [key, fetch_attribute(object, attribute)]
            end
          rescue ::Alba::Error, FrozenError, TypeError
            raise
          rescue StandardError => e
            handle_error(e, object, key, attribute)
          end
          arrays.reject(&:empty?).to_h
        end
      end

      def conditional_attribute(object, key, attribute)
        condition = attribute.last
        arity = condition.arity
        return [] if arity <= 1 && !condition.call(object)

        fetched_attribute = fetch_attribute(object, attribute.first)
        attr = if attribute.first.is_a?(Alba::Association)
                 attribute.first.object
               else
                 fetched_attribute
               end
        return [] if arity >= 2 && !condition.call(object, attr)

        [key, fetched_attribute]
      end

      def handle_error(error, object, key, attribute)
        on_error = @_on_error || Alba._on_error
        case on_error
        when :raise, nil
          raise
        when :nullify
          [key, nil]
        when :ignore
          []
        when Proc
          on_error.call(error, object, key, attribute, self.class)
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

      def fetch_attribute(object, attribute)
        case attribute
        when Symbol
          object.public_send attribute
        when Proc
          instance_exec(object, &attribute)
        when Alba::One, Alba::Many
          within = check_within
          return unless within

          attribute.to_hash(object, params: params, within: within)
        when Hash # Typed Attribute
          typed_attribute(object, attribute)
        else
          raise ::Alba::Error, "Unsupported type of attribute: #{attribute.class}"
        end
      end

      def typed_attribute(object, hash)
        attr_name = hash[:attr_name]
        type = hash[:type]
        type_converter = hash[:type_converter]
        value, result = type_check(object, attr_name, type)
        return value if result
        raise TypeError if !result && !type_converter

        type_converter = type_converter_for(type) if type_converter == true
        type_converter.call(value)
      rescue TypeError
        raise TypeError, "Attribute #{attr_name} is expected to be #{type} but actually #{value.nil? ? 'nil' : value.class.name}."
      end

      def type_check(object, attr_name, type)
        value = object.public_send(attr_name)
        type_correct = case type
                       when :String, ->(klass) { klass == String }
                         value.is_a?(String)
                       when :Integer, ->(klass) { klass == Integer }
                         value.is_a?(Integer)
                       when :Boolean
                         [true, false].include?(attr_name)
                       else
                         raise Alba::UnsupportedType, "Unknown type: #{type}"
                       end
        [value, type_correct]
      end

      def type_converter_for(type)
        case type
        when :String, ->(klass) { klass == String }
          ->(object) { object.to_s }
        when :Integer, ->(klass) { klass == Integer }
          ->(object) { Integer(object) }
        when :Boolean
          ->(object) { !!object }
        else
          raise Alba::UnsupportedType, "Unknown type: #{type}"
        end
      end

      def check_within
        case @within
        when Hash # Traverse within tree
          @within.fetch(_key.to_sym, nil)
        when Array # within tree ends with Array
          @within.find { |item| item.to_sym == _key.to_sym } # Check if at least one item in the array matches current resource
        when Symbol # within tree could end with Symbol
          @within == _key.to_sym # Check if the symbol matches current resource
        when true # In this case, Alba serializes all associations.
          true
        when nil, false # In these cases, Alba stops serialization here.
          false
        else
          raise Alba::Error, "Unknown type for within option: #{@within.class}"
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
      def attributes(*attrs, if: nil, **attrs_with_types) # rubocop:disable Naming/MethodParameterName
        if_value = binding.local_variable_get(:if)
        attrs.each do |attr_name|
          attr = if_value ? [attr_name.to_sym, if_value] : attr_name.to_sym
          @_attributes[attr_name.to_sym] = attr
        end
        attrs_with_types.each do |attr_name, type_and_converter|
          attr_name = attr_name.to_sym
          type, type_converter = type_and_converter
          typed_attr = {attr_name: attr_name, type: type, type_converter: type_converter}
          attr = if_value ? [typed_attr, if_value] : typed_attr
          @_attributes[attr_name] = attr
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
      # @param root [Boolean] decides if root key also should be transformed
      def transform_keys(type, root: nil)
        @_transform_keys = type.to_sym
        @_transforming_root_key = root
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
