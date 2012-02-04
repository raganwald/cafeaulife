# # Cafe au Life
# **(c) 2012 Reginald Braithwaite**
#
# Cafe au Life is freely distributable under the terms of the
# [MIT license](http://en.wikipedia.org/wiki/MIT_License).

# Cafe au Life is an implementation of John Conway's [Game of Life][life] cellular automata
# written in [CoffeeScript][cs]. Cafe au Life runs on [Node.js][node], it is not designed
# to run as an interactive program in a browser window.
#
# Cafe au Life's Github project is [here](https://github.com/raganwald/cafeaulife/). This file,
# [cafeaulife.coffee][source] contains the core engine for computing the future of any life universe
# of size `2^n | n > 1`. The algorithm is optimized for computing very large numbers of generations
#  of very large and complex life patterns with a high degree of regularity such as implementing
# Turing machines.
#
# As such, it is particularly poorly suited for animating displays a generation at a time. But it
# is still a beautiful algorithm that touches on the soul of life’s “physics."
#
# ![Gosper's Glider Gun](http://raganwald.github.com/cafeaulife/docs/gospers_glider_gun.gif)
#
# *(Gosper's Glider Gun. This was the first gun discovered, and proved that Life patterns can grow indefinitely.)*
#
# ### Conway's Life and other two-dimensional cellular automata
#
# The Life Universe is an infinite two-dimensional matrix of cells. Cells are indivisible and are in either of two states,
# commonly called "alive" and "dead." Time is represented as discrete quanta called either "ticks" or "generations."
# With each generation, a rule is applied to decide the state the cell will assume. The rules are decided simultaneously,
# and there are only two considerations: The current state of the cell, and the states of the cells in its
# [Moore Neighbourhood][moore], the eight cells adjacent horizontally, vertically, or diagonally.
#
# Cafe au Life implements Conway's Game of Life, as well as other "[life-like][ll]" games in the same family.
#
# [ll]: http://www.conwaylife.com/wiki/Cellular_automaton#Well-known_Life-like_cellular_automata
# [moore]: http://en.wikipedia.org/wiki/Moore_neighborhood
# [source]: https://github.com/raganwald/cafeaulife/blob/master/lib/cafeaulife.coffee
# [life]: http://en.wikipedia.org/wiki/Conway's_Game_of_Life
# [cs]: http://jashkenas.github.com/coffee-script/
# [node]: http://nodejs.org
#
# ## Why
#
# ![Period 24 Glider Gun](http://raganwald.github.com/cafeaulife/docs/Trueperiod24gun.png)
#
# *(A period 24 Glider Gun. Gliders of different periods are useful for synchronizing signals in complex
# Life machines.)*
#
# Cafe au Life is based on Bill Gosper's brilliant [HashLife][hl] algorithm. HashLife is usually implemented in C and optimized
# to run very long simulations with very large 'boards' stinking fast. The HashLife algorithm is, in a word,
# **a beautiful design**, one that is "in the book." To read its description is to feel the desire to explore it on a computer.
#
# Broadly speaking, HashLife has two major components. The first is a high level algorithm that is implementation independent.
# This algorithm exploits repetition and redundancy, aggressively 'caching' previously computed results for regions of the board.
# The second component is the cache itself, which is normally implemented cleverly in C to exploit memory and CPU efficiency
# in looking up precomputed results.
#
# Cafe au Life is an exercise in exploring the beauty of HashLife's recursive caching or results, while accepting that the
# performance in a JavaScript application will not be anything to write home about.
#
# [hl]: http://en.wikipedia.org/wiki/Hashlife

# ### Baseline Setup

# Cafe au Life uses [Underscore.js][u] extensively:
#
# [u]: http://documentcloud.github.com/underscore/
_ = require('underscore')

# Play with Node and some browsers
exports ?= window or this

# A handy function for generating quadrants that are the cartesian products of a collection
# multiplied by itself once for each quadrant.
cartesian_product = (collection) ->
  _.reduce(
    _.reduce(
      _.reduce( {nw, ne, se, sw} for nw in collection for ne in collection for se in collection for sw in collection
      , (x, y) -> x.concat(y))
    , (x, y) -> x.concat(y))
  , (x, y) -> x.concat(y))

# A function for turning any array or object into a dictionary function
#
# (see also: [Reusable Abstractions in CoffeeScript][reuse])
#
# [reuse]: https://github.com/raganwald/homoiconic/blob/master/2012/01/reuseable-abstractions.md#readme
dfunc = (dictionary) ->
  (indices...) ->
    indices.reduce (a, i) ->
      a[i]
    , dictionary

# ### Cells

# The smallest unit of Life is the Cell:
class Cell
  constructor: (@hash) ->
  toValue: ->
    @hash
  to_json: ->
    [@hash]
  level: ->
    0
  empty_copy: ->
    Cell.Dead
  toString: ->
    '' + @hash

# The two canonical cells. No more should ever be created. In C++ terms, `new` is private.
Cell.Alive = new Cell(1)
Cell.Dead = new Cell(0)

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
#       ....I....
#       ....I....
#       ....I....
#       ....I....
#       ====#====
#       ....I....
#       ....I....
#       ....I....
#       ....I....
#     sw         se

# The squares of size four are in turn each composed of four squares of size two (`2^1`):
#
#     nw           ne
#       ..|..I..|..
#       ..|..I..|..
#       --+--I--+--
#       ..|..I..|..
#       ..|..I..|..
#       =====#=====
#       ..|..I..|..
#       ..|..I..|..
#       --+--I--+--
#       ..|..I..|..
#       ..|..I..|..
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

# An id for debugging purposes
debug_id = 0

# HashLife represents each unique square as a structure with four quadrants:
class Square

  # Squares are constructed from four quadrant squares or cells and store a hash used
  # to locate the square in the cache
  constructor: ({@nw, @ne, @se, @sw}) ->
    @hash = Square.cache.hash(this)

    @debug_id = (debug_id += 1)

    # `to_json` is a memoized method
    @to_json = _.memoize( ->
      a =
        nw: @nw.to_json()
        ne: @ne.to_json()
        se: @se.to_json()
        sw: @sw.to_json()
      b =
        top: _.map( _.zip(a.nw, a.ne), ([left, right]) ->
          if _.isArray(left)
            left.concat(right)
          else
            [left, right]
        )
        bottom: _.map( _.zip(a.sw, a.se), ([left, right]) ->
          if _.isArray(left)
            left.concat(right)
          else
            [left, right]
        )
      b.top.concat(b.bottom)
    )

    # `toString` is a memoized method
    @toString = _.memoize( ->
      (_.map @to_json(), (row) ->
        ([' ', '*'][c] for c in row).join('')
      ).join('\n')
    )

  # The level increases with the log2 of the length of the size.
  # So level 1 is 2x2, level 2 is 4x4, level 3 is 8x8, and so on.
  level: ->
    @nw.level() + 1

  # Find or create an empty square with the same dimensions
  empty_copy: ->
    empty_quadrant = @nw.empty_copy()
    Square.cache.find_or_create_by_quadrant
      nw: empty_quadrant
      ne: empty_quadrant
      se: empty_quadrant
      sw: empty_quadrant

  # Find or create a smaller square centered on this square
  deflate_by: (extant) ->
    return this if extant is 0
    Square.cache.find_or_create_by_quadrant(
      _.reduce [0..(extant - 1)], (quadrants) ->
        nw: quadrants.nw.se
        ne: quadrants.ne.sw
        se: quadrants.se.nw
        sw: quadrants.sw.ne
      , this
    )

  # Find or create a larger square centered on this square with
  # the excess composed of empty squares
  inflate_by: (extant) ->
    if extant is 0
      return this
    else
      empty_quadrant = @nw.empty_copy()
      Square.cache
        .find_or_create_by_quadrant
          nw: Square.cache.find_or_create_by_quadrant
            nw: empty_quadrant
            ne: empty_quadrant
            se: @nw
            sw: empty_quadrant
          ne: Square.cache.find_or_create_by_quadrant
            nw: empty_quadrant
            ne: empty_quadrant
            se: empty_quadrant
            sw: @ne
          se: Square.cache.find_or_create_by_quadrant
            nw: @se
            ne: empty_quadrant
            se: empty_quadrant
            sw: empty_quadrant
          sw: Square.cache.find_or_create_by_quadrant
            nw: empty_quadrant
            ne: @sw
            se: empty_quadrant
            sw: empty_quadrant
        .inflate_by(extant - 1)

# ### The Speed of Light
#
# In Life, the "Speed of Light" or "*c*" is one cell vertically, horizontally, or diagonally in any direction. Meaning, that cause and effect cannot travel faster than *c*.
#
# One consequence of this fundamental limit is that given a square of size `2^n | n > 1` at time `t`, HashLife has all the information it needs to calculate the alive and dead cells for the inner square of size `2^n - 2` at time `t+1`. For example, if HashLife has this square at time `t`:
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

# ### Seeding Cafe au Life with squares of size four

# `generate_seeds_from_rule` generates the size four "seed" squares that actually calculate their results
# from the life-like game rules. All larger squares decompose recursively into size four squares, and thus
# do not need to know anything about the rules.
#
# The default, `generate_seeds_from_rule()`, is equivalent to `generate_seeds_from_rule([2,3],[3])`, which
# invokes Conway's Game of Life, commonly written as 23/3. Other games can be invoked with their survival
# and birth counts, e.g. `generate_seeds_from_rule([1,3,5,7], [1,3,5,7])` invokes
# [Replicator](http://www.conwaylife.com/wiki/Replicator_(CA))
_.defaults exports,
  generate_seeds_from_rule: (survival = [2,3], birth = [3]) ->

    # Bail if we are given the same rules and already have generated the expected number of seeds
    return Square.cache.current_rules if Square.cache.current_rules?.toString() is {survival, birth}.toString() and Square.cache.bucketed() >= 65552

    # The rules expressed as a dictionary function
    rule = dfunc [
      (if birth.indexOf(x) >= 0 then Cell.Alive else Cell.Dead) for x in [0..9]
      (if survival.indexOf(x) >= 0 then Cell.Alive else Cell.Dead) for x in [0..9]
    ]

    # successfor function for any cell
    succ = (cells, row, col) ->
      current_state = cells[row][col]
      neighbour_count = cells[row-1][col-1] + cells[row-1][col] +
        cells[row-1][col+1] + cells[row][col-1] +
        cells[row][col+1] + cells[row+1][col-1] +
        cells[row+1][col] + cells[row+1][col+1]
      rule(current_state, neighbour_count)

    # A SeedSquare knows how to calculate its own result from
    # the rules
    class SeedSquare extends Square
      constructor: (params) ->
        super(params)

        # Seed squares compute a result one generation into the future. (We will see later that
        # larger squares results more generations into the future.)
        @generations = 1

        # `result` calculates the inner result square. The method
        # is memoized.
        @result = _.memoize(
          ->
            a = @to_json()
            Square.cache.find
              nw: succ(a, 1,1)
              ne: succ(a, 1,2)
              se: succ(a, 2,2)
              sw: succ(a, 2,1)
        )

    # Clear the cache out
    Square.cache.clear()

    # The canonical 2x2 squares are initialized from the cartesian product
    # of every possible cell. 2 possible cells to the power of 4 quadrants gives sixteen
    # possible 2x2 squares.
    #
    # 2x2 squares do not compute results
    all_2x2_squares = cartesian_product([Cell.Dead, Cell.Alive]).map (quadrants) ->
      Square.cache.add new Square(quadrants)

    # The canonical 4x4 squares are initialized from the cartesian product of
    # every possible 2x2 square. 16 possible 2x2 squares to the power of 4 quadrants
    # gives 65,536 possible 4x4 squares.
    #
    # 4x4 squares know how to compute their 2x2 results, and as we saw above, they
    # memoize those results so that they are only computed once. (A variation of
    # memoizing the result computation is to compute it when generating the 4x4 square,
    # thus "compiling" the supplied rules into a table of 65,536 rules taht is looked
    # up at runtime.)
    #
    # We will see below that all larger squares compute their results by recursively
    # combining the results of smaller squares, so therefore all such computations
    # will terminate when they reach a square of size 4x4.
    cartesian_product(all_2x2_squares).forEach (quadrants) ->
      Square.cache.add new SeedSquare(quadrants)

    # Put the rules in the cache and return them.
    Square.cache.current_rules = {survival, birth}

# ---
#
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
          .find_or_create_by_quadrant
            nw: square.nw.ne
            ne: square.ne.nw
            se: square.ne.sw
            sw: square.nw.se
          .result()
        ee: Square.cache
          .find_or_create_by_quadrant
            nw: square.ne.sw
            ne: square.ne.se
            se: square.se.ne
            sw: square.se.nw
          .result()
        ss: Square.cache
          .find_or_create_by_quadrant
            nw: square.sw.ne
            ne: square.se.nw
            se: square.se.sw
            sw: square.sw.se
          .result()
        ww: Square.cache
          .find_or_create_by_quadrant
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
          .find_or_create_by_quadrant
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
          .find_or_create_by_quadrant
            nw: @nw
            ne: @nn
            se: @cc
            sw: @ww
        ne: Square.cache
          .find_or_create_by_quadrant
            nw: @nn
            ne: @ne
            se: @ee
            sw: @cc
        se: Square.cache
          .find_or_create_by_quadrant
            nw: @cc
            ne: @ee
            se: @se
            sw: @ss
        sw: Square.cache
          .find_or_create_by_quadrant
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
      Square.cache.find_or_create_by_quadrant
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

  # The number of generation is double the number of generations of any of its quadrants
      @generations = @nw.generations * 2

# ### Memoizing: The "Hash" in HashLife
#
# HashLife gets a tremendous speed-up by storing and reusing squares in a giant cache.
# Any result, at any scale, that has been computed before is reused. This is extremely
# efficient when dealing with patterns that contain a great deal of redundancy, such as
# the kinds of patterns constructed for the purpose of emulating circuits or machines in Life.
#
# Once Cafe au Life has calculated the results for the 65K possible four-by-four
# squares, the rules are no longer applied to any generation: Any pattern of any size is
# recursively computed terminating in a four-by-four square that has already been computed and cached.

# ### Representing the cache
Square.cache =

  # chosen from http://primes.utm.edu/lists/small/10000.txt. Probably should be > 65K
  num_buckets: 99991
  buckets: []

  clear: ->
    @buckets = []

  # `hash` returns an integer for any square
  hash: (square_like) ->
    if square_like.hash?
      square_like.hash
    else
      ((3 *@hash(square_like.nw)) + (37 * @hash(square_like.ne))  + (79 * @hash(square_like.se)) + (131 * @hash(square_like.sw)))

  # `find` locates a square in the cache if it exists
  find: (quadrants) ->
    bucket_number = @hash(quadrants) % @num_buckets
    if @buckets[bucket_number]?
      _.find @buckets[bucket_number], (sq) ->
        sq.nw is quadrants.nw and sq.ne is quadrants.ne and sq.se is quadrants.se and sq.sw is quadrants.sw

  # `Like find`, but creates a `RecursivelyComputableSquare` if none is found
  find_or_create_by_quadrant: (quadrants) ->
    found = @find(quadrants)
    if found
      found
    else
      @add(new RecursivelyComputableSquare(quadrants))

  # `Like find_or_create_by_quadrant`, but takes json as an argument. Useful
  # for seeding the world from a data file.
  find_or_create_by_json: (json) ->
    unless _.isArray(json[0]) and json[0].length is json.length
      throw 'must be a square'
    if json.length is 1
      if json[0][0] instanceof Cell
        json[0][0]
      else if json[0][0] is 0
        Cell.Dead
      else if json[0][0] is 1
        Cell.Alive
      else
        throw 'a 1x1 square must contain a zero, one, or Cell'
    else
      half_length = json.length / 2
      @find_or_create_by_quadrant
        nw: @find_or_create_by_json(
          json.slice(0, half_length).map (row) ->
            row.slice(0, half_length)
        )
        ne: @find_or_create_by_json(
          json.slice(0, half_length).map (row) ->
            row.slice(half_length)
        )
        se: @find_or_create_by_json(
          json.slice(half_length).map (row) ->
            row.slice(half_length)
        )
        sw: @find_or_create_by_json(
          json.slice(half_length).map (row) ->
            row.slice(0, half_length)
        )

  # An agnostic method that can find or create anything
  find_or_create: (params) ->
    if _.isArray(params)
      @find_or_create_by_json(params)
    else if _.all( ['nw', 'ne', 'se', 'sw'], ((quadrant) -> params[quadrant] instanceof Cell) )
      @find_or_create_by_quadrant params
    else if _.all( ['nw', 'ne', 'se', 'sw'], ((quadrant) -> params[quadrant] instanceof Square) )
      @find_or_create_by_quadrant params
    else
      throw "Cache can't handle #{JSON.stringify(params)}"

  # adds a square to the cache if it doesn't already exist
  add: (square) ->
    bucket_number = square.hash % @num_buckets
    @buckets[bucket_number] ||= []
    @buckets[bucket_number] = _.reject @buckets[bucket_number], (found) ->
      found.nw is square.nw and found.ne is square.ne and found.se is square.se and found.sw is square.sw
    @buckets[bucket_number].push(square)
    square

  # For debugging, it can be useful to count the number of squares in the cache
  bucketed: ->
    _.reduce @buckets, (sum, bucket) ->
      sum + bucket.length
    , 0

  # For debugging, it can be useful to get an idea of the relative sizes of the cache buckets
  histogram: ->
    _.reduce @buckets, (histo, bucket) ->
      _.tap histo, (h) ->
        h[bucket.length] ||= 0
        h[bucket.length] += 1
    , []

# Expose `find_or_create` through `Square`
Square.find_or_create = (params) ->
  @cache.find_or_create(params)

# Export `Square` and `Cell` for regular use and specs
_.defaults exports, {Square, Cell}

# p.s. This document was generated from [cafeaulife.coffee][source] using [Docco][docco].
# [source]: https://github.com/raganwald/cafeaulife/blob/master/lib/cafeaulife.coffee
# [docco]: http://jashkenas.github.com/docco/