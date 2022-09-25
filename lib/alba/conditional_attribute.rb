module Alba
  # Represents attribute with `if` option
  class ConditionalAttribute
    CONDITION_UNMET = Object.new.freeze
    public_constant :CONDITION_UNMET # It's public for use in `Alba::Resource`

    # @param body [Symbol, Proc, Alba::Association, Alba::TypedAttribute] real attribute wrapped with condition
    # @param condition [Symbol, Proc] condition to check
    def initialize(body:, condition:)
      @body = body
      @condition = condition
    end

    # Returns attribute body if condition passes
    #
    # @param resource [Alba::Resource]
    # @param object [Object] needed for collection, each object from collection
    # @return [ConditionalAttribute::CONDITION_UNMET, Object] CONDITION_UNMET if condition is unmet, fetched attribute otherwise
    def with_passing_condition(resource:, object: nil)
      return CONDITION_UNMET unless condition_passes?(resource, object)

      fetched_attribute = yield(@body)
      return fetched_attribute if fetched_attribute.nil? || !with_two_arity_proc_condition

      return CONDITION_UNMET unless resource.instance_exec(object, attribute_from_association_body_or(fetched_attribute), &@condition)

      fetched_attribute
    end

    private

    def condition_passes?(resource, object)
      if @condition.is_a?(Proc)
        arity = @condition.arity
        # We can return early to skip fetch_attribute if arity is 1
        # When arity is 2, we check the condition later
        return true if arity >= 2
        return false if arity <= 1 && !resource.instance_exec(object, &@condition)

        true
      else # Symbol
        resource.__send__(@condition)
      end
    end

    def with_two_arity_proc_condition
      @condition.is_a?(Proc) && @condition.arity >= 2
    end

    def attribute_from_association_body_or(fetched_attribute)
      @body.is_a?(Alba::Association) ? @body.object : fetched_attribute
    end
  end
end
