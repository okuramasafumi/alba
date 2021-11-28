module Alba
  # Module for printing deprecation warning
  module Deprecation
    # Similar to {Kernel.warn} but prints caller as well
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
