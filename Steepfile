# frozen_string_literal: true

D = Steep::Diagnostic

target :lib do
  signature 'sig'

  check 'lib' # Directory name
  # ignore "lib/templates/*.rb"

  library 'json'                   # For JSON serialization
  library 'logger'                 # For logging support
  library 'pathname'               # For file paths

  # Optional libraries that Alba supports
  # library "active_support"       # For Rails integration
  # library "oj"                   # For Oj backend

  configure_code_diagnostics(D::Ruby.lenient) # Start with lenient settings
  # configure_code_diagnostics do |hash|
  #   hash[D::Ruby::NoMethod] = :information
  #   hash[D::Ruby::UnknownConstant] = :hint
  # end
end

# target :test do
#   signature "sig", "sig-private"
#
#   check "test"
#
#   # library "pathname"              # Standard libraries
# end
