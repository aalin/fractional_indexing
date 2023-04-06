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
    raise FIError, "#{a} >= #{b}" if b && a >= b
    raise FIError, "trailing zero" if (a[-1] == "0") || (b && (b[-1] == "0"))
    if b
      # remove longest common prefix.  pad `a` with 0s as we
      # go.  note that we don't need to pad `b`, because it can't
      # end before `a` while traversing the common prefix.
      n = 0
      a = a.ljust(b.length, "0")
      for i in 0..(b.length - 1)
        if a[i] == b[i]
          n += 1
        else
          break
        end
      end

      return b[0..(n - 1)] + midpoint(a[n..-1], b[n..-1], digits) if n > 0
    end

    # first digits (or lack of digit) are different
    digit_a = a.empty? ? 0 : digits.index(a[0])
    digit_b = b.nil? ? digits.length : digits.index(b[0])
    if digit_b - digit_a > 1
      min_digit = (0.5 * (digit_a + digit_b)).round
      return digits[min_digit]
    else
      if b && b.length > 1
        return b[0]
      else
        # `b` is null or has length 1 (a single digit).
        # the first digit of `a` is the previous digit to `b`,
        # or 9 if `b` is null.
        # given, for example, midpoint('49', '5'), return
        # '4' + midpoint('9', null), which will become
        # '4' + '9' + midpoint('', null), which is '495'
        digit_a = a.empty? ? 0 : digits.index(a[0])
        return digits[digit_a] + midpoint(a[1..-1], nil, digits)
      end
    end
  end

  def self.validate_integer(i)
    unless i.length == get_integer_length(i[0])
      raise FIError, "invalid integer part of order key: #{i}"
    end
  end

  def self.get_integer_length(head)
    if ('a'..'z').cover?(head)
      return head.ord - 'a'.ord + 2
    elsif ('A'..'Z').cover?(head)
      return 'Z'.ord - head.ord + 2
    end
    raise FIError, "invalid order key head: " + head
  end

  def self.get_integer_part(key)
    integer_part_length = get_integer_length(key[0])
    raise FIError, "invalid order key: #{key}" if integer_part_length > key.size

    key[0...integer_part_length]
  end

  def self.validate_order_key(key)
    raise FIError, "invalid order key: #{key}" if key == SMALLEST_INTEGER

    # get_integer_part() will throw if the first character is bad,
    # or the key is too short.  we'd call it to check these things
    # even if we didn't need the result
    i = get_integer_part(key)
    f = key[i.size..]
    raise FIError, "invalid order key: #{key}" if f[-1] == "0"

    nil
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
      return h + digs.join
    else
      return head + digs.join
    end
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
      h = (head.ord - 1).chr
      if h < 'Z'
        digs.push(digits[-1])
      else
        digs.pop
      end
      return h + digs.join
    else
      return head + digs.join
    end
  end

  def self.generate_key_between(a, b, digits = BASE_62_DIGITS)
    validate_order_key(a) if a
    validate_order_key(b) if b
    raise "a >= b" if a && b && a >= b

    if a == nil
      return INTEGER_ZERO if b == nil
      ib = get_integer_part(b)
      fb = b[ib.length..-1]
      return ib + midpoint("", fb, digits) if ib == SMALLEST_INTEGER
      return ib if ib < b
      res = decrement_integer(ib, digits)
      raise "cannot decrement any more" if res == nil
      return res
    end

    if b == nil
      ia = get_integer_part(a)
      fa = a[ia.length..-1]
      i = increment_integer(ia, digits)
      return ia + midpoint(fa, nil, digits) if i == nil
      return i
    end

    ia = get_integer_part(a)
    fa = a[ia.length..-1]
    ib = get_integer_part(b)
    fb = b[ib.length..-1]
    return ia + midpoint(fa, fb, digits) if ia == ib
    i = increment_integer(ia, digits)
    raise "cannot increment any more" if i == nil

    return i if i < b

    return ia + midpoint(fa, nil, digits)
  end

  # Returns an array of n distinct keys in sorted order.
  # If a and b are both nil, returns [a0, a1, ...]
  # If one or the other is nil, returns consecutive "integer"
  # keys. Otherwise, returns relatively short keys between.
  def self.generate_n_keys_between(a, b, n, digits = BASE_62_DIGITS)
    return [] if n.zero?

    return [generate_key_between(a, b, digits)] if n == 1

    unless b
      c = generate_key_between(a, b, digits)
      result = [c]
      (n - 1).times do
        c = generate_key_between(c, b, digits)
        result << c
      end
      return result
    end

    unless a
      c = generate_key_between(a, b, digits)
      result = [c]
      (n - 1).times do
        c = generate_key_between(a, c, digits)
        result << c
      end
      return result.reverse
    end

    mid = n / 2
    c = generate_key_between(a, b, digits)
    [
      *generate_n_keys_between(a, c, mid.floor, digits),
      c,
      *generate_n_keys_between(c, b, n - mid.floor - 1, digits)
    ]
  end

  # Rounds a float to an integer using decimal.Decimal.quantize with
  # decimal.ROUND_HALF_UP rounding method.
  def self.round_half_up(n)
    (n.to_d.round(0, half: :up)).to_i
  end
end
