require_relative 'association'

module Alba
  # Representing many association
  class Many < Association
    # Recursively converts objects into an Array of Hashes
    #
    # @param target [Object] the object having an association method
    # @param params [Hash] user-given Hash for arbitrary data
    # @return [Array<Hash>]
    def to_hash(target, params: {})
      @object = target.public_send(@name)
      @object = @condition.call(@object, params) if @condition
      return if @object.nil?

      @resource = constantize(@resource)
      @object.map { |o| @resource.new(o, params: params).to_hash }
    end
  end
end
