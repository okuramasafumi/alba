require 'alba/association'

module Alba
  # Representing many association
  class Many < Association
    def to_hash(target)
      objects = target.public_send(@name)
      objects = @condition.call(objects) if @condition
      objects.map { |o| @resource.new(o).to_hash }
    end
  end
end
