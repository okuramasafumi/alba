require_relative 'association'

module Alba
  # Representing one association
  class One < Association
    # Recursively converts an object into a Hash
    #
    # @param target [Object] the object having an association method
    # @param params [Hash] user-given Hash for arbitrary data
    # @return [Hash]
    def to_hash(target, params: {})
      object = target.public_send(@name)
      object = @condition.call(object, params) if @condition
      @resource.new(object, params: params).to_hash
    end
  end
end
