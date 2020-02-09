module Alba
  # This class represents an attribute, which is serialized
  # by either sending message or calling a Proc.
  class Attribute
    def initialize(name:, method:)
      @name = name
      @method = method
    end

    def serialize(target)
      case @method
      when Symbol, String
        target.public_send(@method)
      when Proc
        @method.call(target)
      end
    end
  end
end
