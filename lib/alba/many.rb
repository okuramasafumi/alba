require 'alba/association'

module Alba
  # Representing many association
  class Many < Association
    def to_hash(target, params: {})
      objects = target.public_send(@name)
      objects = @condition.call(objects, params) if @condition
      objects.map { |o| @resource.new(o, params: params).to_hash }
    end
  end
end
