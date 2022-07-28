module Alba
  # JSON:API
  module JSONAPI
    JSONAPI_DSLS = {_id: nil, _type: nil, _meta: nil, _links: {}}.freeze
    private_constant :JSONAPI_DSLS

    ID_AND_TYPE = [:id, :type].freeze
    private_constant :ID_AND_TYPE

    # Association for JSON:API
    # The main purpose is to contain meta and links
    class Association < ::Alba::Association
      @const_cache = {}
      class << self
        attr_reader :const_cache
      end

      attr_reader :meta, :links

      # @see Alba::Association
      def initialize(name:, condition: nil, resource: nil, nesting: nil, meta: nil, links: nil, &block) # rubocop:disable Metrics/ParameterLists
        super(name: name, condition: condition, resource: resource, nesting: nesting, &block)
        @meta = meta
        @links = links
      end
    end

    # rubocop:disable Metrics/MethodLength
    # @api private
    def self.included(base)
      base.include Alba::Resource
      base.class_eval do
        # Initialize
        JSONAPI_DSLS.each do |name, initial|
          instance_variable_set("@#{name}", initial.dup) unless instance_variable_defined?("@#{name}")
        end
      end
      base.layout(inline: jsonapi_proc)
      base.attributes(:id, :type)
      base.extend Alba::JSONAPI::ClassMethods
      base.prepend(Alba::JSONAPI::InstanceMethods)
      super
    end
    # rubocop:enable Metrics/MethodLength

    # For JSON:API layout
    def self.jsonapi_proc
      proc do
        result = {data: serializable_hash}
        result[:meta] = @meta if @meta
        result[:included] = included_data if params[:include]
        result[:links] = @links if @links
        result
      end
    end

    # Instance method called from jsonapi_proc
    module InstanceMethods
      # Initializer, overriding Alba::Resource#initialize
      def initialize(object, params: {}, within: nil, meta: nil, links: nil)
        JSONAPI_DSLS.each_key { |name| instance_variable_set("@#{name}", self.class.__send__(name)) }
        # The default value of `within` is defined with private constant so here we don't want to refer it
        options = within.nil? ? {params: params} : {params: params, within: within}
        super(object, **options)

        @meta = meta
        @_links.transform_keys! { |k| transform_key(k) } if Alba.inferring # links defined in DSL
        @links = transformed_links(links) # links defined in option
      end

      private

      def transformed_links(links)
        if Alba.inferring
          links&.transform_keys { |k| transform_key(k) }
        else
          links
        end
      end

      def converter
        lambda do |obj|
          resource_for(obj)
        end
      end

      def collection_converter
        lambda do |obj, array|
          array << resource_for(obj)
        end
      end

      def resource_for(obj)
        result = identifier_for(obj)
        result[:attributes] = jsonapi_attributes(obj)
        result[:relationships] = relationships(obj) unless associations.empty?
        result[:meta] = instance_eval(&@_meta) if @_meta
        result[:links] = @_links.transform_values { |l| instance_exec(obj, &l) } unless @_links.empty?
        result
      end

      def identifier_for(obj)
        {type: type(obj), id: id(obj)}
      end

      def type(_obj)
        t = self.class._type || fetch_key
        Alba.inferring ? transform_key(t) : t
      end

      def id(obj)
        self.class._id ? obj.__send__(self.class._id) : obj.id
      end

      # Split attributes into plain and association
      def partitioned_attributes
        attributes.partition do |_key, attribute|
          body = attribute.is_a?(Array) ? attribute.first : attribute
          body.is_a?(Symbol) || body.is_a?(Proc) # Otherwise, it's assocition
        end
      end

      def plain_attributes
        partitioned_attributes.first
      end

      def associations
        partitioned_attributes.last
      end

      # Filter plain attributes for `attributes` section in JSONAPI
      def jsonapi_attributes(obj)
        attrs = plain_attributes.reject do |key, _|
          ID_AND_TYPE.include?(key)
        end
        h = {}
        attrs.each do |key, attribute|
          set_key_and_attribute_body_from(obj, key, attribute, h)
        end
        h
      end

      # Filter relationships for `relationships` section in JSONAPI
      def relationships(obj)
        assocs = associations.filter_map do |key, assoc|
          value = assoc.is_a?(Array) ? conditional_relationship(obj, key, assoc) : relationship(obj, key, assoc)
          condition_unmet?(value) ? nil : value
        end
        assocs.to_h
      end

      # TODO: Similar code to `conditional_attribute`, consider refactoring
      def conditional_relationship(obj, key, assoc)
        condition = assoc.last
        if condition.is_a?(Proc)
          conditional_relationship_with_proc(obj, key, assoc.first, condition)
        else
          conditional_relationship_with_symbol(obj, key, assoc.first, condition)
        end
      end

      # TODO: Similar code to `conditional_attribute_with_proc`, consider refactoring
      def conditional_relationship_with_proc(obj, key, assoc, condition)
        conditional_attribute_with_proc(obj, key, assoc, condition) do
          relationship(obj, key, assoc)
        end
      end

      def conditional_relationship_with_symbol(obj, key, assoc, condition)
        conditional_attribute_with_symbol(obj, key, assoc, condition) do
          relationship(obj, key, assoc)
        end
      end

      def relationship(obj, key, assoc)
        data = {data: data_for_relationship(obj, assoc)}
        data[:meta] = assoc.meta.call(obj) if assoc.meta
        data[:links] = get_links(obj, assoc.links) if assoc.links
        key = transform_key(key)
        [key, data]
      end

      def data_for_relationship(obj, association)
        data = fetch_attribute(obj, nil, association)
        type = association.name.to_s.delete_suffix('s').to_sym # TODO: use inflector
        slice_data = lambda do |h|
          next if h.nil? # Circular association

          h.slice!(*ID_AND_TYPE)
          h[:type] = type if h[:type].nil?
          h
        end
        data.is_a?(Array) ? data.map(&slice_data) : slice_data.call(data)
      end

      def get_links(obj, links)
        case links
        when Symbol
          obj.__send__(links)
        when Hash
          links.transform_values do |l|
            get_link(obj, l)
          end
        else
          raise Alba::Error, "Unknown link format: #{links.inspect}"
        end
      end

      def get_link(obj, link)
        if link.is_a?(Proc)
          instance_exec(obj, &link)
        else # Symbol
          obj.__send__(link)
        end
      end

      def included_data
        data = Array(params[:include]).filter_map do |inc|
          assoc = associations.find do |k, _v|
            k.name.to_sym == inc.to_sym
          end
          next unless assoc

          fetch_attribute(object, nil, assoc.last)
        end
        data.flatten
      end
    end

    # Additional DSL
    module ClassMethods
      attr_reader(*JSONAPI_DSLS.keys)

      # @private
      def inherited(subclass)
        JSONAPI_DSLS.each_key { |name| subclass.instance_variable_set("@#{name}", instance_variable_get("@#{name}").clone) }
        super
      end

      def association(name, condition = nil, resource: nil, key: nil, meta: nil, links: nil, **options) # rubocop:disable Metrics/ParameterLists
        nesting = self.name&.rpartition('::')&.first
        assoc = ::Alba::JSONAPI::Association.new(name: name, condition: condition, resource: resource, nesting: nesting, meta: meta, links: links)
        @_attributes[key&.to_sym || name.to_sym] = options[:if] ? [assoc, options[:if]] : assoc
      end
      alias one association
      alias many association
      alias has_one association
      alias has_many association

      # rubocop:disable Naming/AccessorMethodName
      def set_id(id)
        @_id = id
      end

      def set_type(type)
        @_type = type
      end
      # rubocop:enable Naming/AccessorMethodName

      def link(name, &block)
        @_links[name] = block
      end
    end
  end
end
