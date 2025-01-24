# frozen_string_literal: true

require 'erb'
require 'forwardable'

module Alba
  # Layout serialization
  # @api private
  class Layout
    extend Forwardable

    def_delegators :@resource, :object, :params, :serializable_hash, :to_h

    # @param file [String] name of the layout file
    # @param inline [Proc] a proc returning JSON string or a Hash representing JSON
    def initialize(file:, inline:)
      @body = if file
                check_and_return(file, 'File layout must be a String representing filename', String)
              elsif inline
                check_and_return(inline, 'Inline layout must be a Proc returning a Hash or a String', Proc)
              else
                raise ArgumentError, 'Layout must be either String or Proc'
              end
    end

    # Serialize within layout
    #
    # @param resource [Alba::Resource] the original resource calling this layout
    # @param serialized_json [String] JSON string for embedding
    # @param binding [Binding] context for serialization
    def serialize(resource:, serialized_json:, binding:)
      @resource = resource
      @serialized_json = serialized_json

      if @body.is_a?(String)
        serialize_within_string_layout(binding)
      else
        serialize_within_inline_layout
      end
    end

    private

    attr_reader :serialized_json

    def check_and_return(obj, message, klass)
      raise ArgumentError, message unless obj.is_a?(klass)

      obj
    end

    def serialize_within_string_layout(bnd)
      ERB.new(File.read(@body)).result(bnd)
    end

    def serialize_within_inline_layout
      inline = instance_eval(&@body)
      case inline
      when Hash then encode(inline)
      when String then inline
      else
        raise Alba::Error, 'Inline layout must be a Proc returning a Hash or a String'
      end
    end

    # This methods exists here instead of delegation because
    # `Alba::Resource#encode` is private and it prints warning if we use `def_delegators`
    def encode(hash)
      @resource.instance_eval { encode(hash) }
    end
  end
end
