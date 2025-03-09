# frozen_string_literal: true

require_relative '../test_helper'

class WithStructTest < Minitest::Test
  class RangeResource
    include Alba::Resource

    attributes :begin, :end
  end

  def test_it_works_with_range
    range = 1..3
    assert_equal '{"begin":1,"end":3}', RangeResource.new(range).serialize

    beginless_range = ..10
    assert_equal '{"begin":null,"end":10}', RangeResource.new(beginless_range).serialize

    endless_range = (1..)
    assert_equal '{"begin":1,"end":null}', RangeResource.new(endless_range).serialize
  end
end
