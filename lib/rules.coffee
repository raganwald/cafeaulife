# This module is part of [cafeaulife.coffee](http:cafeaulife.html).
#
# ## Rules Module
#
# The Rules Module provides a method for setting up the [rules][ll] of the Life universe.
#
# [ll]: http://www.conwaylife.com/wiki/Cellular_automaton#Well-known_Life-like_cellular_automata

# ### Setting the rules for this game's "Universe"
#
# There many, many are different possible "games" consisting of cellular automata arranged in a two-dimensional
# matrix. Cafe au Life handles the "life-like" ones, roughly those that have:
#
# * A stable 'quiescent' state. A universe full of empty cells will stay empty.
# * Rules based only on the population of a cell's Moore Neighborhood: Every cell is affected by the population of its eight neighbours, and all eight neighbours are treated identically.
# * Two states.
#
# Given a definition of the state machine for each cell, Cafe au Life performs all the necessary initialization to compute
# the future of a pattern.

# `set_universe_rules` generates the size four "seed" squares that actually calculate their results
# from the life-like game rules. All larger squares decompose recursively into size four squares, and thus
# do not need to know anything about the rules.
#
# The default, `set_universe_rules()`, is equivalent to `set_universe_rules([2,3],[3])`, which
# invokes Conway's Game of Life, commonly written as 23/3. Other games can be invoked with their survival
# and birth counts, e.g. `set_universe_rules([1,3,5,7], [1,3,5,7])` invokes
# [Replicator](http://www.conwaylife.com/wiki/Replicator_(CA))

# ### Baseline Setup
_ = require('underscore')
YouAreDaChef = require('YouAreDaChef').YouAreDaChef
exports ?= window or this

# A handy function for generating quadrants that are the cartesian products of a collection
# multiplied by itself once for each quadrant, and another function for turning any array or object into a dictionary function.
#
# (see also: [Reusable Abstractions in CoffeeScript][reuse])
#
# [reuse]: https://github.com/raganwald/homoiconic/blob/master/2012/01/reuseable-abstractions.md#readme
cartesian_product = (collection) ->
  _.reduce(
    _.reduce(
      _.reduce( {nw, ne, se, sw} for nw in collection for ne in collection for se in collection for sw in collection
      , (x, y) -> x.concat(y))
    , (x, y) -> x.concat(y))
  , (x, y) -> x.concat(y))

dfunc = (dictionary) ->
  (indices...) ->
    indices.reduce (a, i) ->
      a[i]
    , dictionary


exports.mixInto = (exports) ->

  {Square, Cell} = exports

  _.defaults exports,
    set_universe_rules: (survival = [2,3], birth = [3]) ->

      Cell.Alive ?= new Cell(1)
      Cell.Dead  ?= new Cell(0)

      return exports if Square.cache.current_rules?.toString() is {survival, birth}.toString() and Square.cache.bucketed() >= 65552

      rule = dfunc [
        (if birth.indexOf(x) >= 0 then Cell.Alive else Cell.Dead) for x in [0..9]
        (if survival.indexOf(x) >= 0 then Cell.Alive else Cell.Dead) for x in [0..9]
      ]

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
          @result = _.memoize( =>
            a = @to_json()
            Square.cache.find
              nw: succ(a, 1,1)
              ne: succ(a, 1,2)
              se: succ(a, 2,2)
              sw: succ(a, 2,1)
          )

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

      Square.cache.current_rules = {survival, birth}

      exports

# ## The first time through
#
# If this is your first time through the code, read the [Future Module][future] next. You can look at the [Cache][cache] and [API][api] modules at your leisure, they arent really core to the algorithm.
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