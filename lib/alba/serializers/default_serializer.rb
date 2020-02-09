module Alba
  module Serializers
    # DefaultSerializer class is used when a user doesn't specify serializer opt.
    # It's basically an alias of Alba::Serializer, but since it's a module this class simply include it.
    class DefaultSerializer
      include Alba::Serializer
    end
  end
end
