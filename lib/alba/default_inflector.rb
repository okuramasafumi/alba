module Alba
  module DefaultInflector
    begin
      require "active_support/inflector"
    rescue LoadError
      raise ::Alba::Error, "To use transform_keys, please install `ActiveSupport` gem."
    end

    module_function

    def camelize(key)
      ActiveSupport::Inflector.camelize(key)
    end

    def lower_camelize(key)
      ActiveSupport::Inflector.camelize(key, false)
    end

    def dasherize(key)
      ActiveSupport::Inflector.dasherize(key)
    end
  end
end
