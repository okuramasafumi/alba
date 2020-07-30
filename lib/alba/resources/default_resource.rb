module Alba
  module Resources
    # Empty resource class, use this with `class_eval` for
    # inline associations and serializations.
    class DefaultResource
      include ::Alba::Resource
    end
  end
end
