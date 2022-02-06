module Alba
  # Base class for Errors
  class Error < StandardError; end

  # Error class for backend which is not supported
  class UnsupportedBackend < Error; end

  # Error class for type which is not supported
  class UnsupportedType < Error; end
end
