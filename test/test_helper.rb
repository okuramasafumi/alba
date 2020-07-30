require 'coveralls'
Coveralls.wear!

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
require 'alba'
require 'oj' # For backend swapping

require 'minitest/autorun'
