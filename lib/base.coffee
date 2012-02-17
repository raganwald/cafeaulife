# This module is part of [cafeaulife.coffee](http:cafeaulife.html).
#
# ## Base Module
#
# The Base Module provides the `Cell` and `Square` classes, including `RecursivelyComputableSquare`, the foundation of the
# HashLife implementation.

# ### Baseline Setup
_ = require('underscore')
YouAreDaChef = require('YouAreDaChef').YouAreDaChef
exports ?= window or this

# ### Cells

# The smallest unit of Life is the Cell. The constructor is set up to call an `initialize` method to make point-cuts slightly easier.
class Cell
  constructor: (@value) ->
    @initialize.apply(this, arguments)
  initialize: ->

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

# HashLife represents each unique square as a structure with four quadrants.
# Squares are constructed from four quadrant squares or cells and store a hash used
# to locate the square in the cache. As with `Cell`, the constructor is set up to call an `initialize` method to make point-cuts slightly easier.
class Square
  constructor: ({@nw, @ne, @se, @sw}) ->
    @initialize.apply(this, arguments)
  initialize: ->

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

# Our class will be a `RecursivelyComputableSquare`. We'll isolate helpers as we build our class.
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
      nw: @nw.result()
      ne: @ne.result()
      se: @se.result()
      sw: @sw.result()
      nn: Square
        .canonicalize
          nw: @nw.ne
          ne: @ne.nw
          se: @ne.sw
          sw: @nw.se
        .result()
      ee: Square
        .canonicalize
          nw: @ne.sw
          ne: @ne.se
          se: @se.ne
          sw: @se.nw
        .result()
      ss: Square
        .canonicalize
          nw: @sw.ne
          ne: @se.nw
          se: @se.sw
          sw: @sw.se
        .result()
      ww: Square
        .canonicalize
          nw: @nw.sw
          ne: @nw.se
          se: @sw.ne
          sw: @sw.nw
        .result()
      cc: Square
        .canonicalize
          nw: @nw.se
          ne: @ne.sw
          se: @se.nw
          sw: @sw.ne
        .result()

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
class RecursivelyComputableSquare extends Square
  constructor: (quadrants) ->
    super(quadrants)
    @result = _.memoize( ->
      sub_squares = @intermediate_via_subresults().sub_squares()
      Square.canonicalize
        nw: sub_squares.nw.result()
        ne: sub_squares.ne.result()
        se: sub_squares.se.result()
        sw: sub_squares.sw.result()
    )

_.defaults exports, {RecursivelyComputableSquare}

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