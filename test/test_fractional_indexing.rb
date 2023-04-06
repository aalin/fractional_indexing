# frozen_string_literal: true

require "test_helper"

class TestFractionalIndexing < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::FractionalIndexing::VERSION
  end

  def test_it_does_something_useful
    first = FractionalIndexing.generate_key_between(nil, nil)
    assert_equal(first, 'a0')

    # Insert after 1st
    second = FractionalIndexing.generate_key_between(first, nil)
    assert_equal(second, 'a1')

    # Insert after 2nd
    third = FractionalIndexing.generate_key_between(second, nil)
    assert_equal(third, 'a2')

    # Insert before 1st
    zeroth = FractionalIndexing.generate_key_between(nil, first)
    assert_equal(zeroth, 'Zz')

    # Insert in between 2nd and 3rd. Midpoint
    second_and_half = FractionalIndexing.generate_key_between(second, third)
    assert_equal(second_and_half, 'a1V')
  end
end
