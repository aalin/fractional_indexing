# frozen_string_literal: true

# Provides functions for generating ordering strings
# <https://observablehq.com/@dgreensp/implementing-fractional-indexing>
# <https://github.com/aalin/fractional_indexing.rb>
# Ported from Python using ChatGPT:
# <https://github.com/httpie/fractional-indexing-python>

require_relative "fractional_indexing/version"
require "bigdecimal"

module FractionalIndexing
  class Error < StandardError
  end

  BASE_62_DIGITS =
    "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
  SMALLEST_INTEGER = "A00000000000000000000000000"
  INTEGER_ZERO = "a0"

  def self.midpoint(a, b, digits)
    # `a` may be empty string, `b` is null or non-empty string.
    # `a < b` lexicographically if `b` is non-null.
    # no trailing zeros allowed.
    # digits is a string such as '0123456789' for base 10.  Digits must be in
    # ascending character code order!
    raise Error, "#{a} >= #{b}" if b && a >= b
    raise Error, "trailing zero" if a.end_with?("0") || b&.end_with?("0")

    if b
      # remove longest common prefix.  pad `a` with 0s as we
      # go.  note that we don't need to pad `b`, because it can't
      # end before `a` while traversing the common prefix.
      n = b.each_char.with_index.count { |c, i| (a[i] || "0") == c }
      if n > 0
        return b[0...n] + midpoint(a[n..], b[n..], digits)
      end
    end

    # first digits (or lack of digit) are different
    digit_a = a.empty? ? 0 : digits.index(a[0])
    digit_b = b.nil? ? digits.length : digits.index(b[0])
    if digit_b - digit_a > 1
      min_digit = (0.5 * (digit_a + digit_b)).round
      return digits[min_digit]
    else
      # first digits are consecutive
      if b && b.length > 1
        return b[0]
      else
        # `b` is null or has length 1 (a single digit).
        # the first digit of `a` is the previous digit to `b`,
        # or 9 if `b` is null.
        # given, for example, midpoint('49', '5'), return
        # '4' + midpoint('9', null), which will become
        # '4' + '9' + midpoint('', null), which is '495'
        return digits[digit_a] + midpoint(a[1..], nil, digits)
      end
    end
  end

  def self.validate_integer(int)
    unless int.length == get_integer_length(int[0])
      raise Error, "invalid integer part of order key: #{int}"
    end
  end

  def self.get_integer_length(head)
    case head
    in 'a'..'z'
      head.ord - 'a'.ord + 2
    in 'A'..'Z'
      'Z'.ord - head.ord + 2
    else
      raise Error, "invalid order key head: #{head}"
    end
  end

  def self.get_integer_part(key)
    integer_part_length = get_integer_length(key[0])

    if integer_part_length > key.length
      raise Error, "invalid order key: #{key}"
    end

    key.slice(0, integer_part_length)
  end

  def self.validate_order_key(key)
    if key == SMALLEST_INTEGER
      raise Error, "invalid order key: #{key}"
    end

    # get_integer_part() will throw if the first character is bad,
    # or the key is too short.  we'd call it to check these things
    # even if we didn't need the result
    i = get_integer_part(key)
    f = key[i.size..]
    if f.end_with?("0")
      raise Error, "invalid order key: #{key}"
    end
  end

  def self.increment_integer(x, digits)
    validate_integer(x)
    head, *digs = x.chars
    carry = true
    digs.reverse_each do |d|
      i = digits.index(d) + 1
      if i == digits.size
        d.replace('0')
      else
        d.replace(digits[i])
        carry = false
        break
      end
    end
    if carry
      if head == 'Z'
        return 'a0'
      elsif head == 'z'
        return nil
      end
      h = (head.ord + 1).chr
      if h > 'a'
        digs.push('0')
      else
        digs.pop
      end
      h + digs.join
    else
      head + digs.join
    end
  end

  def self.increment_integer!(x, digits)
    increment_integer(x, digits) or raise(Error, "cannot increment anymore")
  end

  def self.decrement_integer(x, digits)
    validate_integer(x)
    head, *digs = x.chars
    borrow = true
    digs.reverse_each do |d|
      i = digits.index(d) - 1
      if i == -1
        d.replace(digits[-1])
      else
        d.replace(digits[i])
        borrow = false
        break
      end
    end
    if borrow
      if head == 'a'
        return 'Z' + digits[-1]
      elsif head == 'A'
        return nil
      end
      h = head.ord.pred.chr
      if h < 'Z'
        digs.push(digits[-1])
      else
        digs.pop
      end
      h + digs.join
    else
      head + digs.join
    end
  end

  def self.decrement_integer!(x, digits)
    decrement_integer(x, digits) or raise(Error, "cannot decrement anymore")
  end

  def self.generate_key_between(a, b, digits = BASE_62_DIGITS)
    validate_order_key(a) if a
    validate_order_key(b) if b
    raise "#{a.inspect} >= #{b.inspect}" if a && b && a >= b

    unless a
      return INTEGER_ZERO unless b

      ib = get_integer_part(b)
      if ib == SMALLEST_INTEGER
        fb = b[ib.length..]
        return ib + midpoint("", fb, digits)
      elsif ib < b
        return ib
      else
        return decrement_integer!(ib, digits)
      end
    end

    unless b
      ia = get_integer_part(a)
      fa = a[ia.length..]
      return increment_integer(ia, digits) || (ia + midpoint(fa, nil, digits))
    end

    ia = get_integer_part(a)
    fa = a[ia.length..]
    ib = get_integer_part(b)
    fb = b[ib.length..]

    if ia == ib
      return ia + midpoint(fa, fb, digits)
    end

    i = increment_integer!(ia, digits)

    return i if i < b

    ia + midpoint(fa, nil, digits)
  end

  # Returns an array of n distinct keys in sorted order.
  # If a and b are both nil, returns [a0, a1, ...]
  # If one or the other is nil, returns consecutive "integer"
  # keys. Otherwise, returns relatively short keys between.
  def self.generate_n_keys_between(a, b, n, digits = BASE_62_DIGITS)
    if n == 0
      return []
    elsif n == 1
      return [generate_key_between(a, b, digits)]
    end

    return n.times.map do
      a = generate_key_between(a, b, digits)
    end unless b

    return n.times.map do
      b = generate_key_between(a, b, digits)
    end.reverse unless a

    mid = (n / 2).floor
    c = generate_key_between(a, b, digits)
    [
      *generate_n_keys_between(a, c, mid, digits),
      c,
      *generate_n_keys_between(c, b, n - mid - 1, digits)
    ]
  end
end
