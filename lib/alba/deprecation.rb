# frozen_string_literal: true

module Alba
  # Module for printing deprecation warning
  # @api private
  module Deprecation
    # Similar to {#warn} but prints caller as well
    #
    # @param message [String] main message to print
    # @return void
    def warn(message)
      Kernel.warn(message)
      Kernel.warn(caller_locations(2..2).first) # For performance reason we use (2..2).first
    end
    module_function :warn
  end
end
