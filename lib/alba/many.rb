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
      objects = target.public_send(@name)
      objects = @condition.call(objects, params) if @condition
      return if objects.nil?

      objects.map { |o| @resource.new(o, params: params).to_hash }
    end
  end
end
