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
  # What if we don't want to move so far forward in time? Well, we don't have to. First, let's assume that
  # we have a method called `result_at_time`. If that's the case, when we generate an intermediate square,
  # we can generate one that is less than `2^(n-2)` generations forward:
  _.extend Square.prototype,
    intermediate_via_subresults_at_time: (t) ->
      new Square.Intermediate
        nw: @nw.result_at_time(t)
        ne: @ne.result_at_time(t)
        se: @se.result_at_time(t)
        sw: @sw.result_at_time(t)
        nn: Square
          .canonicalize
            nw: @nw.ne
            ne: @ne.nw
            se: @ne.sw
            sw: @nw.se
          .result_at_time(t)
        ee: Square
          .canonicalize
            nw: @ne.sw
            ne: @ne.se
            se: @se.ne
            sw: @se.nw
          .result_at_time(t)
        ss: Square
          .canonicalize
            nw: @sw.ne
            ne: @se.nw
            se: @se.sw
            sw: @sw.se
          .result_at_time(t)
        ww: Square
          .canonicalize
            nw: @nw.sw
            ne: @nw.se
            se: @sw.ne
            sw: @sw.nw
          .result_at_time(t)
        cc: Square
          .canonicalize
            nw: @nw.se
            ne: @ne.sw
            se: @se.nw
            sw: @sw.ne
          .result_at_time(t)

  # Armed with this one additional function, we can write a general method for determining the result
  # of a square at an arbitrary point forward in time. Modulo some error checking, we check and see whether
  # we are moving forward more or less than half as much as the maimum amount. If it's more than half, we
  # start by generating the intermediate square from results. If it's less than half, we start by generating
  # the intermediate squre by cropping.
  _.extend Cell.prototype,
    level: 0

  YouAreDaChef(Square)
    .after 'initialize', ->
      @level = @nw.level + 1
      @intermediate_at_time = _.memoize( (t) ->
        @intermediate_via_subresults_at_time(t)
      )
      @subsquares_via_subresults = _.memoize( ->
        @intermediate_via_subresults().sub_squares()
      )

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
        intermediate = @intermediate_at_time(t)
        Square.canonicalize
          nw: Square.canonicalize
            nw: intermediate.nw.se
            ne: intermediate.nn.sw
            se: intermediate.cc.nw
            sw: intermediate.ww.ne
          ne: Square.canonicalize
            nw: intermediate.nn.se
            ne: intermediate.ne.sw
            se: intermediate.ee.nw
            sw: intermediate.cc.ne
          se: Square.canonicalize
            nw: intermediate.cc.se
            ne: intermediate.ee.sw
            se: intermediate.se.nw
            sw: intermediate.ss.ne
          sw: Square.canonicalize
            nw: intermediate.ww.se
            ne: intermediate.cc.sw
            se: intermediate.ss.nw
            sw: intermediate.sw.ne
      else if Math.pow(2, @level - 3) < t < Math.pow(2, @level - 2)
        sub_squares = @subsquares_via_subresults()
        t_remaining = t - Math.pow(2, @level - 3)
        Square.canonicalize
          nw: sub_squares.nw.result_at_time(t_remaining)
          ne: sub_squares.ne.result_at_time(t_remaining)
          se: sub_squares.se.result_at_time(t_remaining)
          sw: sub_squares.sw.result_at_time(t_remaining)
      else if t is Math.pow(2, @level - 2)
        @result
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
        Square.canonicalize
          nw: Square.canonicalize
            nw: empty_quadrant
            ne: empty_quadrant
            se: @nw
            sw: empty_quadrant
          ne: Square.canonicalize
            nw: empty_quadrant
            ne: empty_quadrant
            se: empty_quadrant
            sw: @ne
          se: Square.canonicalize
            nw: @se
            ne: empty_quadrant
            se: empty_quadrant
            sw: empty_quadrant
          sw: Square.canonicalize
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
        new_size = Math.pow(2, @level) + (t * 2)
        new_level = Math.ceil(Math.log(new_size) / Math.log(2))
        base = @pad_by (new_level - @level + 1)
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