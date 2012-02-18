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

  # ### Recap: Squares
  #
  # ![Block laying seed](block_laying_seed.png)
  #
  # *(A small pattern that creates a block-laying switch engine, a "puffer train" that grows forever.)*
  #
  # HashLife operates on square regions of the board, with the length of the side of each square being a natural power of two
  # (`2^1 -> 2`, `2^2 -> 4`, `2^3 -> 8`...). Cells are not considered squares. Therefore, the smallest possible square
  # (of size `2^1`) has cells for each of its four quadrants, while all larger squares (of size `2^n`) have squares of one smaller
  # size (`2^(n-1)`) for each of their four quadrants.
  #
  # For example, a square of size eight (`2^3`) is composed of four squares of size four (`2^2`):
  #
  #     nw         ne
  #       ....|....
  #       ....|....
  #       ....|....
  #       ....|....
  #       ————#————
  #       ....|....
  #       ....|....
  #       ....|....
  #       ....|....
  #     sw         se
  #
  # The squares of size four are in turn each composed of four squares of size two (`2^1`):
  #
  #     nw           ne
  #       ..|..|..|..
  #       ..|..|..|..
  #       ——+——|——+——
  #       ..|..|..|..
  #       ..|..|..|..
  #       —————#—————
  #       ..|..|..|..
  #       ..|..|..|..
  #       ——+——|——+——
  #       ..|..|..|..
  #       ..|..|..|..
  #     sw           se
  #
  # And those in turn are each composed of four cells, which cannot be subdivided. (For simplicity, a Cafe au Life
  # board is represented as one such large square, although the HashLife
  # algorithm can be used to handle any board shape by tiling it with squares.)
  #
  # The key principle behind HashLife is taking advantage of redundancy. Therefore, two squares with the same alive and dead cells
  # are always represented by the same, immutable square objects. HashLife exploits repetition and redundancy by making all squares
  # idempotent and unique. In other words, if two squares contain the same sequence of cells, they are represented by the same
  # instance of class `Square`. For example, there is exactly one representation of a square of size two containing four empty cells:
  #
  #     nw  ne
  #       ..
  #       ..
  #     sw  sw
  #
  # And thus, a square of size four containing sixteen empty cells is represented as four references to the exact same square of
  # size two containing four empty cells:
  #
  #     nw     ne
  #       ..|..
  #       ..|..
  #       --+--
  #       ..|..
  #       ..|..
  #     sw     se
  #
  # And likewise a square of size eight containing sixty-four empty cells is represented as four references to the exact same
  # square of size four containing sixteen empty cells.
  #
  #     nw         ne
  #       ....|....
  #       ....|....
  #       ....|....
  #       ....|....
  #       ----+----
  #       ....|....
  #       ....|....
  #       ....|....
  #       ....|....
  #     sw         se
  #
  # Obviously, the same goes for any configuration of alive and dead cells: There is one unique representation for any possible
  # square and each of its four quadrants is a reference to a unique representation of a smaller square or cell.
  #
  # ### The Speed of Light
  #
  # In Life, the "Speed of Light" or "*c*" is one cell vertically, horizontally, or diagonally in any direction. Meaning,
  # that cause and effect cannot travel faster than *c*.
  #
  # One consequence of this fundamental limit is that given a square of size `2^n | n > 1` at time `t`, HashLife has all
  # the information it needs to calculate the alive and dead cells for the inner square of size `2^n - 2` at time `t+1`.
  # For example, if HashLife has this square at time `t`:
  #
  #     nw        ne
  #       ....|....
  #       ....|....
  #       ....|....
  #       ....|....
  #       ----+----
  #       ....|....
  #       ....|....
  #       ....|....
  #       ....|....
  #     sw        se
  #
  # HashLife can calculate this square at time `t+1`:
  #
  #     nw         ne
  #
  #        ...|...
  #        ...|...
  #        ...|...
  #        ---+---
  #        ...|...
  #        ...|...
  #        ...|...
  #
  #     sw         se
  #
  # And this square at time `t+2`:
  #
  #     nw         ne
  #
  #
  #         ..|..
  #         ..|..
  #         --+--
  #         ..|..
  #         ..|..
  #
  #
  #     sw         se
  #
  # And this square at time `t+3`:
  #
  #     nw        ne
  #
  #
  #
  #          ..
  #          ..
  #
  #
  #
  #     sw        se
  #
  #
  # This is because no matter what is in the cells surrounding our square, their effects cannot propagate
  # faster than the speed of light, one row inward from the edge every step in time.
  #
  # HashLife takes advantage of this by storing enough information to quickly look up the shrinking
  # 'future' for every square of size `2^n | n > 1`. The information is called a square's *result*.
  #
  # ## Computing the result for squares
  #
  # ![Block laying seed](block_laying_seed_2.png)
  #
  # *(Another small pattern that creates a block-laying switch engine, a "puffer train" that grows forever.)*
  #
  # Let's revisit the obvious: Cells do not have results. Also, Squares of size two do not have results,
  # because at time `t+1`, cells outside of the square will affect every cell in the square.
  #
  # The smallest square that computes a result is of size four (`2^2`). Its result is a square of
  # size two (`2^1`) representing the state of those cells at time `t+1`:
  #
  #     ....
  #     .++.
  #     .++.
  #     ....
  #
  # The computation of the four inner `+` cells from their adjacent eight cells is straightforward and
  # is calculated from the basic 2-3 rules or looked up from a table with 65K entries.

  # ## Recursively constructing squares of size eight (and larger)
  #
  # ![Lightweight Spaceship](LWSS.gif)
  #
  # *(A small pattern that moves.)*
  #
  # Now let's consider a square of size eight. For the moment, we can ignore the question of what happens
  # when a square is not in the cache, because when dealing with squares of size eight, we only ever need
  # to look up squares of size four, and they are all seeded in the cache. (Once we have established how
  # to construct the result for a square of size eight, including its result and velocity, we will be able
  # to write out `.find` method to handle looking up squares of size eight and dealing with cache 'misses'
  # by constructing a new square.)

  # Our class will be a `Square.RecursivelyComputable`. We'll isolate helpers as we build our class.
  #
  # We know how to obtain any square of size four using `cache.find`. So what we need is a way to compute
  # the result for any arbitrary square of size eight or larger from quadrant squares one level smaller.
  #
  #
  # Our goal is to compute a result that looks like this (the lines and crosses are part of the result):
  #
  #     nw        ne
  #
  #         +--+
  #         |..|
  #         |..|
  #         +--+
  #
  #     sw        se
  #
  # Given that we know the result for each of those four squares, we can start building an intermediate result.
  # The constructor for `IntermediateResult` takes a square and constructs th epieces of an intermediate square,
  # one that is half way between the level of the square and the level of the square's eventual result.
  #
  # We'll step through that process in the constructor piece by piece.
  #

  # ### Making an Intermediate Square from a Square

  # An intermediate square is half-way in size between a square of size 2^n and 2^(n-1). For a square of size
  # eight, its intermediate square would be size six. Instead of having four quadrants, intermediate squares have
  # nine components.
  #
  # For performace reasons, we don't check, however each component must be a square and not a cell. Thus, you cannot
  # make an intermediate square from a square of size four.
  class Square.Intermediate
    constructor: ({
      @nw, @nn, @ne,
      @ww, @cc, @ee,
      @sw, @ss, @se
    }) ->

  # One way to make an intermediate square is to chop a square up into overlapping
  # subsquares, and take the result of each subsquare. If the square is level `n`, and
  # the subsquares are level `n-1`, the intermediate square will be at time `T+2^(n-3)`.
  #
  # For example, a square of size eight (level 3) can be chopped into overlapping squares of size
  # four (level 2). Since the result of a square of size four is `T+2^0` in its future, the
  # intermediate square constructed from the results of squares of size four will be at time `T+1`
  # relative to the square of size eight.
  #
  # First, Let's look at our square of size eight made up of four component squares of size four (the lines
  # and crosses are part of the components):
  #
  #     nw        ne
  #       +--++--+
  #       |..||..|
  #       |..||..|
  #       +--++--+
  #       +--++--+
  #       |..||..|
  #       |..||..|
  #       +--++--+
  #     sw        se
  #
  # We can take the results of those four quadrants and add them to our intermediate square
  #
  #     nw        ne
  #
  #        nw..ne
  #        nw..ne
  #        ......
  #        ......
  #        sw..se
  #        sw..se
  #
  #     sw        se
  #
  # We can also derive four overlapping squares, these representing `nn`, `ee`, `ss`, and `ww`:
  #
  #          nn
  #       ..+--+..        ..+--+..
  #       ..|..|..        ..|..|..
  #       +-|..|-+        +--++--+
  #       |.+--+.|      w |..||..| e
  #       |.+--+.|      w |..||..| e
  #       +-|..|-+        +--++--+
  #       ..|..|..        ..|..|..
  #       ..+--+..        ..+--+..
  #          ss
  #
  # Deriving these from our four component squares is straightforward, and when we take their results,
  # we fill in four of the five missing blanks for our intermediate square:
  #
  #     nw        ne
  #
  #        ..nn..
  #        ..nn..
  #        ww..ee
  #        ww..ee
  #        ..ss..
  #        ..ss..
  #
  #     sw        se
  #
  # We use a similar method to derive a center square:
  #
  #     nw        ne
  #
  #        ......
  #        .+--+.
  #        .|..|.
  #        .|..|.
  #        .+--+.
  #        ......
  #
  #     sw        se
  #
  # And we extract its result square accordingly:
  #
  #     nw        ne
  #
  #        ......
  #        ......
  #        ..cc..
  #        ..cc..
  #        ......
  #        ......
  #
  #     sw        se
  _.extend Square.prototype,
    intermediate_via_subresults: ->
      new Square.Intermediate
        nw: @nw.result
        ne: @ne.result
        se: @se.result
        sw: @sw.result
        nn: Square
          .canonicalize
            nw: @nw.ne
            ne: @ne.nw
            se: @ne.sw
            sw: @nw.se
          .result
        ee: Square
          .canonicalize
            nw: @ne.sw
            ne: @ne.se
            se: @se.ne
            sw: @se.nw
          .result
        ss: Square
          .canonicalize
            nw: @sw.ne
            ne: @se.nw
            se: @se.sw
            sw: @sw.se
          .result
        ww: Square
          .canonicalize
            nw: @nw.sw
            ne: @nw.se
            se: @sw.ne
            sw: @sw.nw
          .result
        cc: Square
          .canonicalize
            nw: @nw.se
            ne: @ne.sw
            se: @se.nw
            sw: @sw.ne
          .result

  # ### Making a Square from an Intermediate Square

  # Okay, we started with a square of size `2^n`, and we make an intermediate square of size
  # `2^(n-.5). Given an intermediate square, we can make a square of size `2^(n-1)` that is forward in time of the
  # intermediate square by taking the result of four overlapping squares, also of size `2^(n-1)`.
  #
  #     nw        ne  nw        ne
  #
  #        nwnn..        ..nnne
  #        nwnn..        ..nnne
  #        wwcc..        ..ccee
  #        wwcc..        ..ccee
  #        ......        ......
  #        ......        ......
  #
  #     sw        se  sw        se
  #
  #     nw        ne  nw        ne
  #
  #        ......        ......
  #        ......        ......
  #        wwcc..        ..ccee
  #        wwcc..        ..ccee
  #        swss..        ..ssse
  #        swss..        ..ssse
  #
  #     sw        se  sw        se
  #
  # The results of those could be combined like this to form the final square of size `2^(n-1):
  #
  #     nw        ne
  #
  #        ......
  #        .nwne.
  #        .nwne.
  #        .swse.
  #        .swse.
  #        ......
  #
  #     sw        se
  #
  # We're not going to do that here, we're just responsible for the geometry.
  _.extend Square.Intermediate.prototype,
    sub_squares: ->
      nw: Square
        .canonicalize
          nw: @nw
          ne: @nn
          se: @cc
          sw: @ww
      ne: Square
        .canonicalize
          nw: @nn
          ne: @ne
          se: @ee
          sw: @cc
      se: Square
        .canonicalize
          nw: @cc
          ne: @ee
          se: @se
          sw: @ss
      sw: Square
        .canonicalize
          nw: @ww
          ne: @cc
          se: @ss
          sw: @sw

  # Given all the work we just did on `Square.Intermediate`, we now have everything we need to compute the
  # result of any square of size eight or larger, any time in the future from time `T+1` to time `T+2^(n-1)`
  # where `n` is the level of the square.
  #
  # The naïve result is obtained as follows: We construct a Square.Intermediate from subresults (moving
  # forward to `T+2^(n-2)`), and then we obtain its overlapping squares and take *their* results (moving
  # forward `2^(n-2)` again, for a total advance of `2^(n-1)`).
  #
  # The only complication is that we memoize the result for performance... This is HashLife after all, and we
  # do not like to repeat ourselves in either Space or Time.
  class Square.RecursivelyComputable extends Square
    constructor: (quadrants) ->
      super(quadrants)
      sub_squares = @intermediate_via_subresults().sub_squares()
      @result = Square.canonicalize
        nw: sub_squares.nw.result
        ne: sub_squares.ne.result
        se: sub_squares.se.result
        sw: sub_squares.sw.result

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

# ## The first time through
#
# If this is your first time through the code, and you've already read the [Rules Module][rules], you can look at the [Cache][cache] and [API][api] modules.
#
# [menagerie]: http:menagerie.html
# [api]: http:api.html
# [future]: http:future.html
# [cache]: http:cache.html
# [canonical]: https://en.wikipedia.org/wiki/Canonicalization
# [rules]: http:rules.html

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