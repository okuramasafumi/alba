module Alba
  module Resources
    # Empty resource class, use this with `class_eval` for
    # inline associations and serializations.
    class DefaultResource
      include Alba::Resource

      def self.reset
        @_attributes = {}
      end
    end
  end
end
