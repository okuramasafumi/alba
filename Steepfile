# frozen_string_literal: true

D = Steep::Diagnostic

target :lib do
  signature 'sig'

  check 'lib' # Directory name
  # ignore "lib/templates/*.rb"

  library 'json'                   # For JSON serialization
  library 'logger'                 # For logging support
  library 'pathname'               # For file paths
  library 'erb'
  library 'forwardable'

  # Optional libraries that Alba supports
  # Third-party Rails APIs are declared locally because the gems do not ship RBS.
  # library "oj"                   # For Oj backend

  configure_code_diagnostics(D::Ruby.strict) do |diagnostics|
    # These require inline source annotations, which this library deliberately
    # avoids in production code, or arise from checking mixins outside their
    # eventual Class context.
    diagnostics[D::Ruby::FallbackAny] = :information
    diagnostics[D::Ruby::UnannotatedEmptyCollection] = :information
    diagnostics[D::Ruby::UnexpectedSuper] = :information
    diagnostics[D::Ruby::BlockTypeMismatch] = :information
    diagnostics[D::Ruby::UnexpectedPositionalArgument] = :information
    diagnostics[D::Ruby::UnexpectedKeywordArgument] = :information
  end
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
