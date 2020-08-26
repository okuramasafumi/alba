require 'alba/association'

module Alba
  # Representing one association
  class One < Association
    def to_hash(target, params: {})
      object = target.public_send(@name)
      object = @condition.call(object, params) if @condition
      @resource.new(object, params: params).to_hash
    end
  end
end
