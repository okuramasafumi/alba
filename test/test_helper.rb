require 'coveralls'
Coveralls.wear!

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
require 'alba'
unless ENV['OS'] == 'Windows_NT'
  require 'oj' # For backend swapping
end

require 'minitest/autorun'
