require 'alba/version'
require 'json'

# Core module
module Alba
  class Error < StandardError; end

  def self.backend=(backend)
    @backend = backend&.to_sym
  end

  def self.backend
    @backend
  end

  def self.serialize(object)
    fallback = ->(resource) { resource.to_json }
    case backend
    when :oj
      begin
        require 'oj'
        ->(resource) { Oj.dump(resource) }
      rescue LoadError
        fallback
      end
    else
      fallback
    end.call(object)
  end
end
