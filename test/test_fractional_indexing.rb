# frozen_string_literal: true

require "test_helper"

class TestFractionalIndexing < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::FractionalIndexing::VERSION
  end

  BASE_10_DIGITS = ("0".."9").to_a.join

  def test_generate_n_keys_between
    assert_equal(
      FractionalIndexing.generate_n_keys_between(nil, nil, 5, BASE_10_DIGITS).join(' '),
      "a0 a1 a2 a3 a4"
    )
    assert_equal(
      FractionalIndexing.generate_n_keys_between('a4', nil, 10, BASE_10_DIGITS).join(' '),
      "a5 a6 a7 a8 a9 b00 b01 b02 b03 b04"
    )
    assert_equal(
      FractionalIndexing.generate_n_keys_between(nil, "a0", 5, BASE_10_DIGITS).join(' '),
      "Z5 Z6 Z7 Z8 Z9"
    )
    assert_equal(
      FractionalIndexing.generate_n_keys_between("a0", "a2", 20, BASE_10_DIGITS).join(' '),
      "a01 a02 a03 a035 a04 a05 a06 a07 a08 a09 a1 a11 a12 a13 a14 a15 a16 a17 a18 a19"
    )
  end

  def test_readme_examples
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
