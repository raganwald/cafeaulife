# This module is part of [cafeaulife.coffee](http:cafeaulife.html).
#
# ## Future Module
#
# The Future Module provides methods for computing the future of a pattern, taking into account its ability to grow beyond
# the size of its container square.

# ### The Life "Universe"
#
# The `result` given for class `Square` is handy, but not directly useful for computing the future of a pattern,
# because it computes the future of the *center* of a square, not the future of a square. Of course, the future of
# a square depends very much on what surrounds it, and there is an algorithm for computing the future of a surface
# tiled with squares.
#
# However, there is a special case that interests us, the future of a square that sits within an otherwise empty
# Life "Universe." When we build a Life pattern and run it into the future, we are specifically considering the
# case where a square is surrounded by empty squares and may grow beyond the boundaries of the initial square.
#
# This module mixes special case functionality for computing the `future` of a square into `Square` and `Cell`.

# ### Baseline Setup
_ = require('underscore')
YouAreDaChef = require('YouAreDaChef').YouAreDaChef
exports ?= window or this


exports.mixInto = ({Square, Cell}) ->

  # ### Computing a result for a time less than `T+2^(n-1)`
  #
  # What if we don't want to move so far forward in time? Well, we don't have to. First, let's revist our
  # intermediate square. Here's another way to make an intermediate square from a square, we crop an existing
  # square to its size. This produces an intermediate square at time T+0 relative to the square:
  #
  #     nw        ne
  #       ........
  #       .nwnnne.
  #       .nwnnne.
  #       .wwccee.
  #       .wwccee.
  #       .swssse.
  #       .swssse.
  #       ........
  #     sw        se
  YouAreDaChef(Square)
    .after 'initialize', ->
      @level = @nw.level + 1

  _.extend Cell.prototype,
    level:
      0

  _.extend Square.prototype,
    intermediate_via_crop: ->
      new Square.Intermediate
        nw: Square.canonicalize
          nw: @nw.nw.se
          ne: @nw.ne.sw
          se: @nw.se.nw
          sw: @nw.sw.ne
        nn: Square.canonicalize
          nw: @nw.ne.se
          ne: @ne.nw.sw
          se: @ne.sw.nw
          sw: @nw.se.ne
        ne: Square.canonicalize
          nw: @ne.nw.se
          ne: @ne.ne.se
          se: @ne.se.nw
          sw: @ne.sw.ne
        ww: Square.canonicalize
          nw: @nw.sw.se
          ne: @nw.se.sw
          se: @sw.ne.nw
          sw: @sw.nw.ne
        cc: Square.canonicalize
          nw: @nw.se.se
          ne: @ne.sw.sw
          se: @se.nw.nw
          sw: @sw.ne.ne
        ee: Square.canonicalize
          nw: @ne.sw.se
          ne: @ne.se.sw
          se: @sw.ne.nw
          sw: @sw.nw.ne
        sw: Square.canonicalize
          nw: @sw.nw.se
          ne: @sw.ne.sw
          se: @sw.se.nw
          sw: @sw.sw.ne
        ss: Square.canonicalize
          nw: @sw.ne.se
          ne: @se.nw.sw
          se: @se.sw.nw
          sw: @sw.se.ne
        se: Square.canonicalize
          nw: @se.nw.se
          ne: @se.ne.se
          se: @se.se.nw
          sw: @se.sw.ne

  # Armed with this one additional function, we can write a general method for determining the result
  # of a square at an arbitrary point forward in time. Modulo some error checking, we check and see whether
  # we are moving forward more or less than half as much as the maimum amount. If it's more than half, we
  # start by generating the intermediate square from results. If it's less than half, we start by generating
  # the intermediate squre by cropping.
  _.extend Square.prototype,
    result_at_time_zero: ->
      Square.canonicalize
        nw: @nw.se
        ne: @ne.sw
        se: @se.nw
        sw: @sw.ne
    result_at_time: (t) ->
      if t < 0
        throw "We do not have a time machine"
      else if t is 0
        @result_at_time_zero()
      else if t <= Math.pow(2, @level - 3)
        sub_squares = @intermediate_via_crop().sub_squares()
        Square.canonicalize
          nw: sub_squares.nw.result_at_time(t)
          ne: sub_squares.ne.result_at_time(t)
          se: sub_squares.se.result_at_time(t)
          sw: sub_squares.sw.result_at_time(t)
      else if Math.pow(2, @level - 3) < t < Math.pow(2, @level - 2)
        sub_squares = @intermediate_via_subresults().sub_squares()
        t_remaining = t - Math.pow(2, @level - 3)
        Square.canonicalize
          nw: sub_squares.nw.result_at_time(t_remaining)
          ne: sub_squares.ne.result_at_time(t_remaining)
          se: sub_squares.se.result_at_time(t_remaining)
          sw: sub_squares.sw.result_at_time(t_remaining)
      else if t is Math.pow(2, @level - 2)
        @result()
      else if t > Math.pow(2, @level - 2)
        throw "I can't go further forward than #{Math.pow(2, @level - 2)}"

  # ### Computing the future of a square
  #
  # Let's say we have a square and we wish to determine its future at time `t`.
  # We calculate the smallest square that could possible contain its future, taking
  # into account that the pattern in the square could grow once cell in each direction
  # per generation.
  #
  # We then double the size and embed our pattern in the center. This becomes our base
  # square: It's our square embdedded in a possible vast empty square. We then take the
  # base square's `result_at_time(t)` which gives us the future of our pattern.
  #
  # We start with the ability to make empty copies of things.
  _.extend Cell.prototype,
    empty_copy: ->
      Cell.Dead

  _.extend Square.prototype,
    empty_copy: ->
      empty_quadrant = @nw.empty_copy()
      Square.canonicalize
        nw: empty_quadrant
        ne: empty_quadrant
        se: empty_quadrant
        sw: empty_quadrant

    pad_by: (extant) ->
      if extant is 0
        return this
      else
        empty_quadrant = @nw.empty_copy()
        Square.cache
          .canonicalize
            nw: Square.cache.canonicalize
              nw: empty_quadrant
              ne: empty_quadrant
              se: @nw
              sw: empty_quadrant
            ne: Square.cache.canonicalize
              nw: empty_quadrant
              ne: empty_quadrant
              se: empty_quadrant
              sw: @ne
            se: Square.cache.canonicalize
              nw: @se
              ne: empty_quadrant
              se: empty_quadrant
              sw: empty_quadrant
            sw: Square.cache.canonicalize
              nw: empty_quadrant
              ne: @sw
              se: empty_quadrant
              sw: empty_quadrant
          .pad_by(extant - 1)

    future_at_time: (t) ->
      if t < 0
        throw "We do not have a time machine"
      else if t is 0
        this
      else
        base = @pad_by Math.ceil(Math.log(t) / Math.log(2)) + 1
        base.result_at_time(t)

# ---
#
# **(c) 2012 [Reg Braithwaite](http://reginald.braythwayt.com)** ([@raganwald](http://twitter.com/raganwald))
#
# Cafe au Life is freely distributable under the terms of the [MIT license](http://en.wikipedia.org/wiki/MIT_License).
#
# The annotated source code was generated directly from the [original source][source] using [Docco][docco].
#
# [source]: https://github.com/raganwald/cafeaulife/blob/master/lib
# [docco]: http://jashkenas.github.com/docco/