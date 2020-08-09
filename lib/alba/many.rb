require 'alba/association'

module Alba
  # Representing many association
  class Many < Association
    def to_hash(target)
      objects = target.public_send(@name)
      @resource ||= resource_class
      objects.map { |o| @resource.new(o).to_hash }
    end
  end
end
