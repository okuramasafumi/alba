module Alba
  # Empty cache store class for compatibility
  class NullCacheStore
    # Just yield, not to change existing behavior
    def fetch(_key)
      yield
    end
  end
end
