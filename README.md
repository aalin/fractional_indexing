# Fractional Indexing

This is based on [Implementing Fractional Indexing
](https://observablehq.com/@dgreensp/implementing-fractional-indexing) by [David Greenspan
](https://github.com/dgreensp).

Fractional indexing is a technique to create an ordering that can be used for [Realtime Editing of Ordered Sequences](https://www.figma.com/blog/realtime-editing-of-ordered-sequences/).

This implementation includes variable-length integers, and the prepend/append optimization described in David's article.

## Installation

Install the gem and add to the application's Gemfile by executing:

    $ bundle add fractional_indexing

If bundler is not being used to manage dependencies, install the gem by executing:

    $ gem install fractional_indexing

## Usage

```ruby
require "fractional_indexing"

first = FractionalIndexing.generate_key_between(None, None)
raise unless first == 'a0'

# Insert after 1st
second = FractionalIndexing.generate_key_between(first, None)
raise unless second == 'a1'

# Insert after 2nd
third = FractionalIndexing.generate_key_between(second, None)
raise unless third == 'a2'

# Insert before 1st
zeroth = FractionalIndexing.generate_key_between(None, first)
raise unless zeroth == 'Zz'

# Insert in between 2nd and 3rd. Midpoint
second_and_half = FractionalIndexing.generate_key_between(second, third)
raise unless second_and_half == 'a1V'
```

## Other Languages

This is a Ruby port of the [Python port](https://github.com/httpie/fractional-indexing-python) of the [original JavaScript implementation](https://github.com/rocicorp/fractional-indexing).
That means that this implementation is byte-for-byte compatible with:

| Language   | Repo                                                 |
| ---------- | ---------------------------------------------------- |
| JavaScript | https://github.com/rocicorp/fractional-indexing      |
| Go         | https://github.com/rocicorp/fracdex                  |
| Python     | https://github.com/httpie/fractional-indexing-python |

The code was ported entirely by ChatGPT.
