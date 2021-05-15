module Alba
  # This module creates key transform functions
  module KeyTransformFactory
    class << self
      # Create key transform function for given transform_type
      #
      # @params transform_type [Symbol] transform type
      # @return [Proc] transform function
      # @raise [Alba::Error] when transform_type is not supported
      def create(transform_type)
        case transform_type
        when :camel
          ->(key) { _inflector.camelize(key) }
        when :lower_camel
          ->(key) { _inflector.camelize_lower(key) }
        when :dash
          ->(key) { _inflector.dasherize(key) }
        else
          raise ::Alba::Error, "Unknown transform_type: #{transform_type}. Supported transform_type are :camel, :lower_camel and :dash."
        end
      end

      private

      def _inflector
        Alba.inflector || begin
          require_relative './default_inflector'
          Alba::DefaultInflector
        end
      end
    end
  end
end
