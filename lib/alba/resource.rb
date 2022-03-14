require_relative 'association'
require_relative 'typed_attribute'
require_relative 'deprecation'

module Alba
  # This module represents what should be serialized
  module Resource
    # @!parse include InstanceMethods
    # @!parse extend ClassMethods
    DSLS = {_attributes: {}, _key: nil, _key_for_collection: nil, _meta: nil, _transform_type: :none, _transforming_root_key: false, _on_error: nil, _on_nil: nil, _layout: nil}.freeze # rubocop:disable Layout/LineLength
    private_constant :DSLS

    WITHIN_DEFAULT = Object.new.freeze
    private_constant :WITHIN_DEFAULT

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
      # @param within [Object, nil, false, true] determines what associations to be serialized. If not set, it serializes all associations.
      def initialize(object, params: {}, within: WITHIN_DEFAULT)
        @object = object
        @params = params.freeze
        @within = within
        @method_existence = {} # Cache for `respond_to?` result
        DSLS.each_key { |name| instance_variable_set("@#{name}", self.class.public_send(name)) }
      end

      # Serialize object into JSON string
      #
      # @param key [Symbol, nil, true] DEPRECATED, use root_key instead
      # @param root_key [Symbol, nil, true]
      # @param meta [Hash] metadata for this seialization
      # @return [String] serialized JSON string
      def serialize(key: nil, root_key: nil, meta: {})
        Alba::Deprecation.warn '`key` option to `serialize` method is deprecated, use `root_key` instead.' if key
        key = key.nil? && root_key.nil? ? fetch_key : root_key || key
        hash = if key && key != ''
                 h = {key.to_s => serializable_hash}
                 hash_with_metadata(h, meta)
               else
                 serializable_hash
               end
        serialize_with(hash)
      end
      alias to_json serialize

      # A Hash for serialization
      #
      # @return [Hash]
      def serializable_hash
        collection? ? @object.map(&converter) : converter.call(@object)
      end
      alias to_h serializable_hash

      # @deprecated Use {#serializable_hash} instead
      def to_hash
        warn '[DEPRECATION] `to_hash` is deprecated, use `serializable_hash` instead.'
        serializable_hash
      end

      private

      attr_reader :serialized_json # Mainly for layout

      def encode(hash)
        Alba.encoder.call(hash)
      end

      def serialize_with(hash)
        serialized_json = encode(hash)
        return serialized_json unless @_layout

        @serialized_json = serialized_json
        if @_layout.is_a?(String) # file
          ERB.new(File.read(@_layout)).result(binding)

        else # inline
          serialize_within_inline_layout
        end
      end

      def serialize_within_inline_layout
        inline = instance_eval(&@_layout)
        case inline
        when Hash then encode(inline)
        when String then inline
        else
          raise Alba::Error, 'Inline layout must be a Proc returning a Hash or a String'
        end
      end

      def hash_with_metadata(hash, meta)
        return hash if meta.empty? && @_meta.nil?

        metadata = @_meta ? instance_eval(&@_meta).merge(meta) : meta
        hash[:meta] = metadata
        hash
      end

      def fetch_key
        collection? ? _key_for_collection : _key
      end

      def _key_for_collection
        return @_key_for_collection.to_s unless @_key_for_collection == true && Alba.inferring

        key = resource_name.pluralize
        transforming_root_key? ? transform_key(key) : key
      end

      # @return [String]
      def _key
        return @_key.to_s unless @_key == true && Alba.inferring

        transforming_root_key? ? transform_key(resource_name) : resource_name
      end

      def resource_name
        @resource_name ||= self.class.name.demodulize.delete_suffix('Resource').underscore
      end

      def transforming_root_key?
        @_transforming_root_key.nil? ? Alba.transforming_root_key : @_transforming_root_key
      end

      # rubocop:disable Metrics/MethodLength
      def converter
        lambda do |object|
          arrays = attributes.map do |key, attribute|
            key_and_attribute_body_from(object, key, attribute)
          rescue ::Alba::Error, FrozenError, TypeError
            raise
          rescue StandardError => e
            handle_error(e, object, key, attribute)
          end
          arrays.compact!
          arrays.to_h
        end
      end
      # rubocop:enable Metrics/MethodLength

      # This is default behavior for getting attributes for serialization
      # Override this method to filter certain attributes
      def attributes
        @_attributes
      end

      def key_and_attribute_body_from(object, key, attribute)
        key = transform_key(key)
        if attribute.is_a?(Array) # Conditional
          conditional_attribute(object, key, attribute)
        else
          fetched_attribute = fetch_attribute(object, key, attribute)
          [key, fetched_attribute]
        end
      end

      def conditional_attribute(object, key, attribute)
        condition = attribute.last
        if condition.is_a?(Proc)
          conditional_attribute_with_proc(object, key, attribute.first, condition)
        else
          conditional_attribute_with_symbol(object, key, attribute.first, condition)
        end
      end

      def conditional_attribute_with_proc(object, key, attribute, condition)
        arity = condition.arity
        # We can return early to skip fetch_attribute
        return if arity <= 1 && !instance_exec(object, &condition)

        fetched_attribute = fetch_attribute(object, key, attribute)
        attr = attribute.is_a?(Alba::Association) ? attribute.object : fetched_attribute
        return if arity >= 2 && !instance_exec(object, attr, &condition)

        [key, fetched_attribute]
      end

      def conditional_attribute_with_symbol(object, key, attribute, condition)
        return unless __send__(condition)

        [key, fetch_attribute(object, key, attribute)]
      end

      def handle_error(error, object, key, attribute)
        on_error = @_on_error || Alba._on_error
        case on_error
        when :raise, nil then raise
        when :nullify then [key, nil]
        when :ignore then nil
        when Proc then on_error.call(error, object, key, attribute, self.class)
        else
          raise ::Alba::Error, "Unknown on_error: #{on_error.inspect}"
        end
      end

      # rubocop:disable Metrics/MethodLength
      # @return [Symbol]
      def transform_key(key)
        return key if @_transform_type == :none

        key = key.to_s
        # TODO: Using default inflector here is for backward compatibility
        # From 2.0 it'll raise error when inflector is nil
        inflector = Alba.inflector || begin
          require_relative 'default_inflector'
          Alba::DefaultInflector
        end
        case @_transform_type # rubocop:disable Style/MissingElse
        when :camel then inflector.camelize(key)
        when :lower_camel then inflector.camelize_lower(key)
        when :dash then inflector.dasherize(key)
        when :snake then inflector.underscore(key)
        end.to_sym
      end
      # rubocop:enable Metrics/MethodLength

      def fetch_attribute(object, key, attribute)
        value = case attribute
                when Symbol then fetch_attribute_from_object_and_resource(object, attribute)
                when Proc then instance_exec(object, &attribute)
                when Alba::Association then yield_if_within(attribute.name.to_sym) { |within| attribute.to_h(object, params: params, within: within) }
                when TypedAttribute then attribute.value(object)
                else
                  raise ::Alba::Error, "Unsupported type of attribute: #{attribute.class}"
                end
        value.nil? && nil_handler ? instance_exec(object, key, attribute, &nil_handler) : value
      end

      def fetch_attribute_from_object_and_resource(object, attribute)
        has_method = @method_existence[attribute]
        has_method = @method_existence[attribute] = object.respond_to?(attribute) if has_method.nil?
        has_method ? object.public_send(attribute) : __send__(attribute, object)
      end

      def nil_handler
        @nil_handler ||= (@_on_nil || Alba._on_nil)
      end

      def yield_if_within(association_name)
        within = check_within(association_name)
        yield(within) if within
      end

      def check_within(association_name)
        case @within
        when WITHIN_DEFAULT then WITHIN_DEFAULT # Default value, doesn't check within tree
        when Hash then @within.fetch(association_name, nil) # Traverse within tree
        when Array then @within.find { |item| item.to_sym == association_name }
        when Symbol then @within == association_name
        when nil, true, false then false # Stop here
        else
          raise Alba::Error, "Unknown type for within option: #{@within.class}"
        end
      end

      # Detect if object is a collection or not.
      # When object is a Struct, it's Enumerable but not a collection
      def collection?
        @object.is_a?(Enumerable) && !@object.is_a?(Struct)
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

      # Defining methods for DSLs and disable parameter number check since for users' benefits increasing params is fine

      # Set multiple attributes at once
      #
      # @param attrs [Array<String, Symbol>]
      # @param if [Proc] condition to decide if it should serialize these attributes
      # @param attrs_with_types [Hash<[Symbol, String], [Array<Symbol, Proc>, Symbol]>]
      #   attributes with name in its key and type and optional type converter in its value
      # @return [void]
      def attributes(*attrs, if: nil, **attrs_with_types) # rubocop:disable Naming/MethodParameterName
        if_value = binding.local_variable_get(:if)
        assign_attributes(attrs, if_value)
        assign_attributes_with_types(attrs_with_types, if_value)
      end

      def assign_attributes(attrs, if_value)
        attrs.each do |attr_name|
          attr = if_value ? [attr_name.to_sym, if_value] : attr_name.to_sym
          @_attributes[attr_name.to_sym] = attr
        end
      end
      private :assign_attributes

      def assign_attributes_with_types(attrs_with_types, if_value)
        attrs_with_types.each do |attr_name, type_and_converter|
          attr_name = attr_name.to_sym
          type, type_converter = type_and_converter
          typed_attr = TypedAttribute.new(name: attr_name, type: type, converter: type_converter)
          attr = if_value ? [typed_attr, if_value] : typed_attr
          @_attributes[attr_name] = attr
        end
      end
      private :assign_attributes_with_types

      # Set an attribute with the given block
      #
      # @param name [String, Symbol] key name
      # @param options [Hash<Symbol, Proc>]
      # @option options [Proc] if a condition to decide if this attribute should be serialized
      # @param block [Block] the block called during serialization
      # @raise [ArgumentError] if block is absent
      # @return [void]
      def attribute(name, **options, &block)
        raise ArgumentError, 'No block given in attribute method' unless block

        @_attributes[name.to_sym] = options[:if] ? [block, options[:if]] : block
      end

      # Set association
      #
      # @param name [String, Symbol] name of the association, used as key when `key` param doesn't exist
      # @param condition [Proc, nil] a Proc to modify the association
      # @param resource [Class<Alba::Resource>, String, nil] representing resource for this association
      # @param key [String, Symbol, nil] used as key when given
      # @param options [Hash<Symbol, Proc>]
      # @option options [Proc] if a condition to decide if this association should be serialized
      # @param block [Block]
      # @return [void]
      # @see Alba::Association#initialize
      def association(name, condition = nil, resource: nil, key: nil, **options, &block)
        nesting = self.name&.rpartition('::')&.first
        assoc = Association.new(name: name, condition: condition, resource: resource, nesting: nesting, &block)
        @_attributes[key&.to_sym || name.to_sym] = options[:if] ? [assoc, options[:if]] : assoc
      end
      alias one association
      alias many association
      alias has_one association
      alias has_many association

      # Set key
      #
      # @param key [String, Symbol]
      # @deprecated Use {#root_key} instead
      def key(key)
        Alba::Deprecation.warn '[DEPRECATION] `key` is deprecated, use `root_key` instead.'
        @_key = key.respond_to?(:to_sym) ? key.to_sym : key
      end

      # Set root key
      #
      # @param key [String, Symbol]
      # @param key_for_collection [String, Symbol]
      # @raise [NoMethodError] when key doesn't respond to `to_sym` method
      def root_key(key, key_for_collection = nil)
        @_key = key.to_sym
        @_key_for_collection = key_for_collection&.to_sym
      end

      # Set key to true
      #
      # @deprecated Use {#root_key!} instead
      def key!
        Alba::Deprecation.warn '[DEPRECATION] `key!` is deprecated, use `root_key!` instead.'
        @_key = true
        @_key_for_collection = true
      end

      # Set root key to true
      def root_key!
        @_key = true
        @_key_for_collection = true
      end

      # Set metadata
      def meta(&block)
        @_meta = block
      end

      # Set layout
      #
      # @params file [String] name of the layout file
      # @params inline [Proc] a proc returning JSON string or a Hash representing JSON
      def layout(file: nil, inline: nil)
        @_layout = validated_file_layout(file) || validated_inline_layout(inline)
      end

      def validated_file_layout(filename)
        case filename
        when String, nil then filename
        else
          raise ArgumentError, 'File layout must be a String representing filename'
        end
      end
      private :validated_file_layout

      def validated_inline_layout(inline_layout)
        case inline_layout
        when Proc, nil then inline_layout
        else
          raise ArgumentError, 'Inline layout must be a Proc returning a Hash or a String'
        end
      end
      private :validated_inline_layout

      # Delete attributes
      # Use this DSL in child class to ignore certain attributes
      #
      # @param attributes [Array<String, Symbol>]
      def ignoring(*attributes)
        Alba::Deprecation.warn '`ignoring` is deprecated now. Instead please use `attributes` instance method to filter out attributes.'
        attributes.each do |attr_name|
          @_attributes.delete(attr_name.to_sym)
        end
      end

      # Transform keys as specified type
      #
      # @param type [String, Symbol] one of `snake`, `:camel`, `:lower_camel`, `:dash` and `none`
      # @param root [Boolean, nil] decides if root key also should be transformed
      #   When it's `nil`, Alba's default setting will be applied
      # @raise [Alba::Error] when type is not supported
      def transform_keys(type, root: nil)
        type = type.to_sym
        unless %i[none snake camel lower_camel dash].include?(type)
          # This should be `ArgumentError` but for backward compatibility it raises `Alba::Error`
          raise ::Alba::Error, "Unknown transform type: #{type}. Supported type are :camel, :lower_camel and :dash."
        end

        @_transform_type = type
        @_transforming_root_key = root
      end

      # Set error handler
      # If this is set it's used as a error handler overriding global one
      #
      # @param handler [Symbol] `:raise`, `:ignore` or `:nullify`
      # @param block [Block]
      def on_error(handler = nil, &block)
        raise ArgumentError, 'You cannot specify error handler with both Symbol and block' if handler && block
        raise ArgumentError, 'You must specify error handler with either Symbol or block' unless handler || block

        @_on_error = handler || block
      end

      # Set nil handler
      #
      # @param block [Block]
      def on_nil(&block)
        @_on_nil = block
      end
    end
  end
end
