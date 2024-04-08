require_relative 'association'
require_relative 'constants'
require 'ostruct'

module Alba
  # Represents attribute with `if` option
  # @api private
  class ConditionalAttribute
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
    # @return [Alba::REMOVE_KEY, Object] REMOVE_KEY if condition is unmet, fetched attribute otherwise
    def with_passing_condition(resource:, object: nil)
      return Alba::REMOVE_KEY unless condition_passes?(resource, object)

      fetched_attribute = yield(@body)
      return fetched_attribute unless with_two_arity_proc_condition

      return Alba::REMOVE_KEY unless resource.instance_exec(object, objectize(fetched_attribute), &@condition)

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

    # OpenStruct is used as a simple solution for converting Hash or Array of Hash into an object
    # Using OpenStruct is not good in general, but in this case there's no other solution
    def objectize(fetched_attribute)
      return fetched_attribute unless @body.is_a?(Alba::Association)

      if fetched_attribute.is_a?(Array)
        fetched_attribute.map do |hash|
          OpenStruct.new(hash)
        end
      else
        OpenStruct.new(fetched_attribute)
      end
    end
  end
end
