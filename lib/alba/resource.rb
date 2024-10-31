require_relative 'association'
require_relative 'conditional_attribute'
require_relative 'constants'
require_relative 'typed_attribute'
require_relative 'nested_attribute'
require_relative 'deprecation'
require_relative 'layout'

module Alba
  # This module represents what should be serialized
  module Resource
    # @!parse include InstanceMethods
    # @!parse extend ClassMethods
    DSLS = {_attributes: {}, _key: nil, _key_for_collection: nil, _meta: nil, _transform_type: :none, _transforming_root_key: false, _key_transformation_cascade: true, _on_error: nil, _on_nil: nil, _layout: nil, _collection_key: nil, _helper: nil, _resource_methods: []}.freeze # rubocop:disable Layout/LineLength
    private_constant :DSLS

    WITHIN_DEFAULT = Object.new.freeze
    private_constant :WITHIN_DEFAULT

    # `setup` method is meta-programmatically defined here for performance.
    # @private
    def self.included(base) # rubocop:disable Metrics/MethodLength
      super
      setup_method_body = 'private def _setup;'
      base.class_eval do
        # Initialize
        DSLS.each do |name, initial|
          instance_variable_set("@#{name}", initial.dup) unless instance_variable_defined?("@#{name}")
          setup_method_body << "@#{name} = self.class.#{name};"
        end
        base.define_method(:encode, Alba.encoder)
      end
      setup_method_body << 'end'
      base.class_eval(setup_method_body, __FILE__, __LINE__ + 1)
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
        @params = params
        @within = within
        _setup
      end

      # Serialize object into JSON string
      #
      # @param root_key [Symbol, nil, true]
      # @param meta [Hash] metadata for this seialization
      # @return [String] serialized JSON string
      def serialize(root_key: nil, meta: {})
        serialize_with(as_json(root_key: root_key, meta: meta))
      end

      if Gem::Version.new(RUBY_VERSION) < Gem::Version.new('3.0')
        # For Rails compatibility
        # The first options is a dummy parameter but required
        # You can pass empty Hash if you don't want to pass any arguments
        #
        # @see #serialize
        # @see https://github.com/rails/rails/blob/7-0-stable/actionpack/lib/action_controller/metal/renderers.rb#L156
        def to_json(options, root_key: nil, meta: {})
          _to_json(root_key, meta, options)
        end
      else
        # For Rails compatibility
        # The first options is a dummy parameter
        #
        # @see #serialize
        # @see https://github.com/rails/rails/blob/7-0-stable/actionpack/lib/action_controller/metal/renderers.rb#L156
        def to_json(options = {}, root_key: nil, meta: {})
          _to_json(root_key, meta, options)
        end
      end

      # Returns a Hash correspondng {#serialize}
      #
      # @param root_key [Symbol, nil, true]
      # @param meta [Hash] metadata for this seialization
      # @return [Hash]
      def as_json(root_key: nil, meta: {})
        key = root_key.nil? ? fetch_key : root_key
        key = Alba.regularize_key(key)
        if key && !key.empty?
          h = {key => serializable_hash}
          hash_with_metadata(h, meta)
        else
          serializable_hash
        end
      end

      # A Hash for serialization
      #
      # @return [Hash]
      def serializable_hash
        collection? ? serializable_hash_for_collection : converter.call(@object)
      end
      alias to_h serializable_hash

      private

      def _to_json(root_key, meta, options)
        options.reject! { |k, _| %i[layout prefixes template status].include?(k) } # Rails specific guard
        names = options.filter_map { |k, v| k unless v.nil? }
        unless names.empty?
          names.sort!
          names.map! { |s| "\"#{s}\"" }
          message = "You passed #{names.join(', ')} options but ignored. Please refer to the document: https://github.com/okuramasafumi/alba/blob/main/docs/rails.md"
          Kernel.warn(message)
        end
        serialize(root_key: root_key, meta: meta)
      end

      def serialize_with(hash)
        serialized_json = encode(hash)
        return serialized_json unless @_layout

        @_layout.serialize(resource: self, serialized_json: serialized_json, binding: binding)
      end

      def hash_with_metadata(hash, meta)
        return hash if meta.empty? && @_meta.nil?

        metadata = @_meta ? instance_eval(&@_meta).merge(meta) : meta
        hash[:meta] = metadata
        hash
      end

      def serializable_hash_for_collection
        if @_collection_key
          @object.to_h do |item|
            k = item.public_send(@_collection_key)
            key = Alba.regularize_key(k)
            [key, converter.call(item)]
          end
        else
          @object.each_with_object([], &collection_converter)
        end
      end

      # @return [String]
      def fetch_key
        k = collection? ? _key_for_collection : _key
        transforming_root_key? ? transform_key(k) : k
      end

      def _key_for_collection
        k = @_key_for_collection == true ? resource_name(pluralized: true) : @_key_for_collection
        Alba.regularize_key(k)
      end

      def _key
        k = @_key == true ? resource_name(pluralized: false) : @_key
        Alba.regularize_key(k)
      end

      def resource_name(pluralized: false)
        inflector = Alba.inflector
        raise Alba::Error, 'You must set inflector when setting root key as true.' unless inflector

        class_name = self.class.name
        suffix = class_name.end_with?('Resource') ? 'Resource' : 'Serializer'
        name = inflector.demodulize(class_name).delete_suffix(suffix)
        underscore_name = inflector.underscore(name)
        pluralized ? inflector.pluralize(underscore_name) : underscore_name
      end

      def transforming_root_key?
        @_transforming_root_key
      end

      def converter
        lambda do |obj|
          attributes_to_hash(obj, {})
        end
      end

      def collection_converter
        lambda do |obj, a|
          a << {}
          h = a.last
          attributes_to_hash(obj, h)
          a
        end
      end

      def attributes_to_hash(obj, hash)
        attributes.each do |key, attribute|
          set_key_and_attribute_body_from(obj, key, attribute, hash)
        rescue ::Alba::Error, FrozenError, TypeError
          raise
        rescue StandardError => e
          handle_error(e, obj, key, attribute, hash)
        end
        hash
      end

      # This is default behavior for getting attributes for serialization
      # Override this method to filter certain attributes
      def attributes
        @_attributes
      end

      # Default implementation for selecting attributes
      # Override this method to filter attributes based on key and value
      def select(_key, _value)
        true
      end

      def set_key_and_attribute_body_from(obj, key, attribute, hash)
        key = transform_key(key)
        value = fetch_attribute(obj, key, attribute)
        return unless select(key, value)

        hash[key] = value unless value == Alba::REMOVE_KEY
      end

      def handle_error(error, obj, key, attribute, hash)
        on_error = @_on_error || :raise
        case on_error # rubocop:disable Style/MissingElse
        when :raise, nil then raise(error)
        when :nullify then hash[key] = nil
        when :ignore then nil
        when Proc
          key, value = on_error.call(error, obj, key, attribute, self.class)
          hash[key] = value
        end
      end

      def transform_key(key)
        return Alba.regularize_key(key) if @_transform_type == :none || key.nil? || key.empty? # We can skip transformation

        inflector = Alba.inflector
        raise Alba::Error, 'Inflector is nil. You must set inflector before transforming keys.' unless inflector

        Alba.regularize_key(_transform_key(inflector, key.to_s))
      end

      def _transform_key(inflector, key)
        case @_transform_type # rubocop:disable Style/MissingElse
        when :camel then inflector.camelize(key)
        when :lower_camel then inflector.camelize_lower(key)
        when :dash then inflector.dasherize(key)
        when :snake then inflector.underscore(key)
        end
      end

      def fetch_attribute(obj, key, attribute) # rubocop:disable Metrics/CyclomaticComplexity
        value = case attribute
                when Symbol then fetch_attribute_from_object_and_resource(obj, attribute)
                when Proc then instance_exec(obj, &attribute)
                when Alba::Association then yield_if_within(attribute.name.to_sym) { |within| attribute.to_h(obj, params: params, within: within) }
                when TypedAttribute then attribute.value(obj)
                when NestedAttribute then attribute.value(object: obj, params: params)
                when ConditionalAttribute then attribute.with_passing_condition(resource: self, object: obj) { |attr| fetch_attribute(obj, key, attr) }
                else raise ::Alba::Error, "Unsupported type of attribute: #{attribute.class}"
                end
        value.nil? && nil_handler ? instance_exec(obj, key, attribute, &nil_handler) : value
      end

      # TODO: from version 3, `_fetch_attribute_from_resource_first` is default
      def fetch_attribute_from_object_and_resource(obj, attribute)
        _fetch_attribute_from_object_first(obj, attribute)
      end

      def _fetch_attribute_from_object_first(obj, attribute)
        obj.__send__(attribute)
      rescue NoMethodError
        __send__(attribute, obj)
      end

      def _fetch_attribute_from_resource_first(obj, attribute)
        if @_resource_methods.include?(attribute)
          begin
            __send__(attribute, obj)
          rescue NoMethodError
            obj.__send__(attribute)
          end
        else
          obj.__send__(attribute)
        end
      end

      def nil_handler
        @_on_nil
      end

      def yield_if_within(association_name)
        within = check_within(association_name)
        within ? yield(within) : Alba::REMOVE_KEY
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

      # This `method_added` is used for defining "resource methods"
      def method_added(method_name)
        _resource_methods << method_name.to_sym unless method_name.to_sym == :_setup
        super
      end

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
      def attributes(*attrs, if: nil, **attrs_with_types)
        if_value = binding.local_variable_get(:if)
        assign_attributes(attrs, if_value)
        assign_attributes_with_types(attrs_with_types, if_value)
      end

      def assign_attributes(attrs, if_value)
        attrs.each do |attr_name|
          attr_name = attr_name.to_sym
          attr = if_value ? ConditionalAttribute.new(body: attr_name, condition: if_value) : attr_name
          @_attributes[attr_name] = attr
        end
      end
      private :assign_attributes

      def assign_attributes_with_types(attrs_with_types, if_value)
        attrs_with_types.each do |attr_name, type_and_converter|
          attr_name = attr_name.to_sym
          type, type_converter = type_and_converter
          typed_attr = TypedAttribute.new(name: attr_name, type: type, converter: type_converter)
          attr = if_value ? ConditionalAttribute.new(body: typed_attr, condition: if_value) : typed_attr
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

        @_attributes[name.to_sym] = options[:if] ? ConditionalAttribute.new(body: block, condition: options[:if]) : block
      end

      # Set association
      #
      # @param name [String, Symbol] name of the association, used as key when `key` param doesn't exist
      # @param condition [Proc, nil] a Proc to modify the association
      # @param resource [Class<Alba::Resource>, String, Proc, nil] representing resource for this association
      # @param key [String, Symbol, nil] used as key when given
      # @param params [Hash] params override for the association
      # @param options [Hash<Symbol, Proc>]
      # @option options [Proc] if a condition to decide if this association should be serialized
      # @param block [Block]
      # @return [void]
      # @see Alba::Association#initialize
      def association(name, condition = nil, resource: nil, key: nil, params: {}, **options, &block)
        key_transformation = @_key_transformation_cascade ? @_transform_type : :none
        assoc = Association.new(
          name: name, condition: condition, resource: resource, params: params, nesting: nesting, key_transformation: key_transformation, helper: @_helper, &block
        )
        @_attributes[key&.to_sym || name.to_sym] = options[:if] ? ConditionalAttribute.new(body: assoc, condition: options[:if]) : assoc
      end
      alias one association
      alias many association
      alias has_one association
      alias has_many association

      def nesting
        if name.nil?
          nil
        else
          name.rpartition('::').first.then { |n| n.empty? ? nil : n }
        end
      end
      private :nesting

      # Set a nested attribute with the given block
      #
      # @param name [String, Symbol] key name
      # @param options [Hash<Symbol, Proc>]
      # @option options [Proc] if a condition to decide if this attribute should be serialized
      # @param block [Block] the block called during serialization
      # @raise [ArgumentError] if block is absent
      # @return [void]
      def nested_attribute(name, **options, &block)
        raise ArgumentError, 'No block given in attribute method' unless block

        key_transformation = @_key_transformation_cascade ? @_transform_type : :none
        attribute = NestedAttribute.new(key_transformation: key_transformation, &block)
        @_attributes[name.to_sym] = options[:if] ? ConditionalAttribute.new(body: attribute, condition: options[:if]) : attribute
      end
      alias nested nested_attribute

      # Set root key
      #
      # @param key [String, Symbol]
      # @param key_for_collection [String, Symbol]
      # @raise [NoMethodError] when key doesn't respond to `to_sym` method
      def root_key(key, key_for_collection = nil)
        @_key = key.to_sym
        @_key_for_collection = key_for_collection&.to_sym
      end

      # Set root key for collection
      #
      # @param key [String, Symbol]
      # @raise [NoMethodError] when key doesn't respond to `to_sym` method
      def root_key_for_collection(key)
        @_key = true
        @_key_for_collection = key.to_sym
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
      # @param file [String] name of the layout file
      # @param inline [Proc] a proc returning JSON string or a Hash representing JSON
      def layout(file: nil, inline: nil)
        @_layout = Layout.new(file: file, inline: inline)
      end

      # Transform keys as specified type
      #
      # @param type [String, Symbol] one of `snake`, `:camel`, `:lower_camel`, `:dash` and `none`
      # @param root [Boolean] decides if root key also should be transformed
      # @param cascade [Boolean] decides if key transformation cascades into inline association
      #   Default is true but can be set false for old (v1) behavior
      # @raise [Alba::Error] when type is not supported
      def transform_keys(type, root: true, cascade: true)
        type = type.to_sym
        unless %i[none snake camel lower_camel dash].include?(type)
          # This should be `ArgumentError` but for backward compatibility it raises `Alba::Error`
          raise ::Alba::Error, "Unknown transform type: #{type}. Supported type are :camel, :lower_camel and :dash."
        end

        @_transform_type = type
        @_transforming_root_key = root
        @_key_transformation_cascade = cascade
      end

      # Sets key for collection serialization
      #
      # @param key [String, Symbol]
      def collection_key(key)
        @_collection_key = key.to_sym
      end

      # Set error handler
      # If this is set it's used as a error handler overriding global one
      #
      # @param handler [Symbol] `:raise`, `:ignore` or `:nullify`
      # @param block [Block]
      def on_error(handler = nil, &block)
        raise ArgumentError, 'You cannot specify error handler with both Symbol and block' if handler && block
        raise ArgumentError, 'You must specify error handler with either Symbol or block' unless handler || block

        @_on_error = block || validated_error_handler(handler)
      end

      def validated_error_handler(handler)
        unless %i[raise ignore nullify].include?(handler)
          # For backward compatibility
          # TODO: Change this to ArgumentError
          raise Alba::Error, "Unknown error handler: #{handler}. It must be one of `:raise`, `:ignore` or `:nullify`."
        end

        handler
      end
      private :validated_error_handler

      # Set nil handler
      #
      # @param block [Block]
      def on_nil(&block)
        @_on_nil = block
      end

      # Define helper methods
      #
      # @param mod [Module] a module to extend
      def helper(mod = @_helper || Module.new, &block)
        mod.module_eval(&block) if block
        extend mod
        @_helper = mod
      end

      # DSL for alias, purely for readability
      def prefer_resource_method!
        alias_method :fetch_attribute_from_object_and_resource, :_fetch_attribute_from_resource_first
      end

      # DSL for alias, purely for readability
      def prefer_object_method!
        alias_method :fetch_attribute_from_object_and_resource, :_fetch_attribute_from_object_first
      end
    end
  end
end
