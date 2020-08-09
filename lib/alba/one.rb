require 'alba/association'

module Alba
  # Representing one association
  class One < Association
    def to_hash(target)
      object = target.public_send(@name)
      @resource ||= resource_class
      @resource.new(object).to_hash
    end
  end
end
