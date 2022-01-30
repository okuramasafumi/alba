module Alba
  # Type converter class is responsible to covnert given object
  # from one class to another
  class TypeConverter
    attr_reader :from, :to

    # @param from [Class]
    # @param to [Class]
    # @param block [Block]
    def initialize(from, to, &block)
      @from = from
      @to = to
      @block = block
    end

    # Convert given object with provided block
    #
    # @param object [Object]
    def call(object)
      @block.call(object)
    end
  end
end
