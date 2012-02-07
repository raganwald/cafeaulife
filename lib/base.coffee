# This module is part of [cafeaulife.coffee](http:cafeaulife.html).
#
# ## Base Module
#
# The Base Module provides the `Cell` and `Square` classes, including `RecursivelyComputableSquare`, the foundation of the
# HashLife implementation.

# ### Baseline Setup

# Cafe au Life uses [Underscore.js][u] extensively:
#
# [u]: http://documentcloud.github.com/underscore/
_ = require('underscore')

# Play with Node and some browsers
exports ?= window or this

# ### Cells

# The smallest unit of Life is the Cell:
class Cell
  constructor: (@value) ->

    # A simple point-cut that allows us to apply advice to contructors.
    @initialize.apply(this, arguments)

  # By default, do nothing
  initialize: ->
  to_json: ->
    [@value]
  toValue: ->
    @value

# Export `Cell`
_.defaults exports, {Cell}

# ### Squares
#
# ![Block laying seed](block_laying_seed.png)
#
# *(A small pattern that creates a block-laying switch engine, a "puffer train" that grows forever.)*

# HashLife operates on square regions of the board, with the length of the side of each square being a natural power of two
# (`2^1 -> 2`, `2^2 -> 4`, `2^3 -> 8`...). Cells are not considered squares. Therefore, the smallest possible square
# (of size `2^1`) has cells for each of its four quadrants, while all larger squares (of size `2^n`) have squares of one smaller
# size (`2^(n-1)`) for each of their four quadrants.

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

# And those in turn are each composed of four cells, which cannot be subdivided. (For simplicity, a Cafe au Life
# board is represented as one such large square, although the HashLife
# algorithm can be used to handle any board shape by tiling it with squares.)

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
# ### Representing squares

# HashLife represents each unique square as a structure with four quadrants:
class Square

  # Squares are constructed from four quadrant squares or cells and store a hash used
  # to locate the square in the cache
  constructor: ({@nw, @ne, @se, @sw}) ->

    # A simple point-cut that allows us to apply advice to contructors.
    @initialize.apply(this, arguments)

  # By default, do nothing
  initialize: ->

# Export `Square`
_.defaults exports, {Square}

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
# Let's revisit the obvious: Cells do not have results. Also, Squares ofsize two do not have results,
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

# Our class will be a `RecursivelyComputableSquare`. We'll isolate helpers:
RecursivelyComputableSquare = do ->

# We know how to obtain any square of size four using `cache.find`. So what we need is a way to compute
# the result for any arbitrary square of size eight or larger from quadrant squares one level smaller.
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

# The class for intermediate results:
  class IntermediateResult

    # We construct an intermediate result from a square of size eight or larger
    constructor: (square) ->

      # For convenience, we'll use Underscore's `extend` rather than a lot of assignments
      # to @nw, @se, et cetera.
      _.extend this,

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
        nw: square.nw.result()
        ne: square.ne.result()
        se: square.se.result()
        sw: square.sw.result()

        # We can also derive four overlapping squares, these representing `n`, `e`, `s`, and `w`:
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
        nn: Square.cache
          .canonicalize_by_quadrant
            nw: square.nw.ne
            ne: square.ne.nw
            se: square.ne.sw
            sw: square.nw.se
          .result()
        ee: Square.cache
          .canonicalize_by_quadrant
            nw: square.ne.sw
            ne: square.ne.se
            se: square.se.ne
            sw: square.se.nw
          .result()
        ss: Square.cache
          .canonicalize_by_quadrant
            nw: square.sw.ne
            ne: square.se.nw
            se: square.se.sw
            sw: square.sw.se
          .result()
        ww: Square.cache
          .canonicalize_by_quadrant
            nw: square.nw.sw
            ne: square.nw.se
            se: square.sw.ne
            sw: square.sw.nw
          .result()

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
        cc: Square.cache
          .canonicalize_by_quadrant
            nw: square.nw.se
            ne: square.ne.sw
            se: square.se.nw
            sw: square.sw.ne
          .result()

    # We have now derived nine squares of size `2^(n-1)`: Four component squares and five we have
    # derived from second-order components. The results we have extracted have all been cached, so
    # we are performing lookups rather than computations.
    #
    # These squares fit together to make a larger intermediate square, one that does not neatly fit
    # into our world of `2^n` quanta:
    #
    #     nw        ne
    #
    #        nwnnne
    #        nwnnne
    #        wwccee
    #        wwccee
    #        swssse
    #        swssse
    #
    #     sw        se

    # ### Obtaining a result from the intermediate square
    result: ->

      # From our nine squares, we can make four *overlapping* squares of size `2^(n-1)`:
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
      overlapping_squares =
        nw: Square.cache
          .canonicalize_by_quadrant
            nw: @nw
            ne: @nn
            se: @cc
            sw: @ww
        ne: Square.cache
          .canonicalize_by_quadrant
            nw: @nn
            ne: @ne
            se: @ee
            sw: @cc
        se: Square.cache
          .canonicalize_by_quadrant
            nw: @cc
            ne: @ee
            se: @se
            sw: @ss
        sw: Square.cache
          .canonicalize_by_quadrant
            nw: @ww
            ne: @cc
            se: @ss
            sw: @sw
      # We can now make a square from the results from each of those quadrants:
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
      Square.cache.canonicalize_by_quadrant
        nw: overlapping_squares.nw.result()
        ne: overlapping_squares.ne.result()
        se: overlapping_squares.se.result()
        sw: overlapping_squares.sw.result()

  # A `RecursivelyComputableSquare` is a square of size eight or larger
  class RecursivelyComputableSquare extends Square
    constructor: (quadrants) ->
      super(quadrants)

      # When we fit the results of an intermediate square within our original square
      # of size eight, we reveal we have a square of size four, `2^(n-1)` as we wanted
      #
      #     nw        ne
      #       ........
      #       ........
      #       ..nwne..
      #       ..nwne..
      #       ..swse..
      #       ..swse..
      #       ........
      #       ........
      #     sw        se
      @result = _.memoize( ->
        new IntermediateResult(this).result()
      )

      # The number of generation is double the number of generations of any of its quadrants.
      # This can also be derived mathematically from the level: `math.pow(2, @level - 1)`
      @generations = @nw.generations * 2

# Export `RecursivelyComputableSquare`
_.defaults exports, {RecursivelyComputableSquare}

# p.s. This document was generated from [cafeaulife.coffee][source] using [Docco][docco].
# [source]: https://github.com/raganwald/cafeaulife/blob/master/lib/cafeaulife.coffee
# [docco]: http://jashkenas.github.com/docco/