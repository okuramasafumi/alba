# frozen_string_literal: true

# This file includes public constants to prevent circular dependencies.
module Alba
  REMOVE_KEY = Object.new.freeze # A constant to remove key from serialized JSON
  public_constant :REMOVE_KEY
end
