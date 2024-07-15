# frozen_string_literal: true

# Fake implementation of custom inflector
module CustomInflector
  module_function

  def camelize(str)
    "camelized_#{str}"
  end

  def camelize_lower(str)
    str
  end

  def dasherize(str)
    str
  end

  def classify(str)
    str
  end

  def demodulize(str)
    str.split('::').last
  end

  def underscore(str)
    str.gsub('::', '/').gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2').gsub(/([a-z\d])([A-Z])/, '\1_\2').tr('-', '_').downcase
  end

  def pluralize(str)
    "#{str}s"
  end
end
