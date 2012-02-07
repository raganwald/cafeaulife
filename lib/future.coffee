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
# However, there is a special case that interests us, the futrue of a square that sits within an otherwise empty
# Life "Universe." When we build a Life pattern and run it into the future, we are specifically considering the
# case where a sqaure is surrounded by empty squares and may grow beyond the boundaries of the initial square.
#
# This module mixes special case functionality for computing the `future` of a square into `Square` and `Cell`.

# ### Baseline Setup

# Cafe au Life uses [Underscore.js][u] extensively:
#
# [u]: http://documentcloud.github.com/underscore/
_ = require('underscore')

# YouAreDaChef provides a nice clean set of semantics for AOP
YouAreDaChef = require('YouAreDaChef').YouAreDaChef

# ### Mix the functionality into `Square` and `Cell`

exports.mixInto = ({Square, Cell}) ->

  # The `result` given for squares is handy, but not directly useful for computing the future of a pattern,
  # because it computes the future of the *center* of a square, not the future of a square. If we imagine
  # a square sitting in the middle of an infinite, empty Life universe, the future of the pattern within
  # the square is going to be larger than the square, it will expand one cell in each direction for every
  # generation into the future.
  #
  # For example, if we start with:
  #
  #     nw  ne
  #       ??
  #       ??
  #     sw  sw
  #
  # After `2^0` generations we double its size:
  #
  #     nw    ne
  #       ????
  #       ????
  #       ????
  #       ????
  #     sw    se
  #
  # After `2^1` more generations we double again:
  #
  #     nw        ne
  #       ????????
  #       ????????
  #       ????????
  #       ????????
  #       ????????
  #       ????????
  #       ????????
  #       ????????
  #     sw        se
  #
  # After `2^2` additional generations on top of that we double yet again:
  #
  #     nw                ne
  #       ????????????????
  #       ????????????????
  #       ????????????????
  #       ????????????????
  #       ????????????????
  #       ????????????????
  #       ????????????????
  #       ????????????????
  #       ????????????????
  #       ????????????????
  #       ????????????????
  #       ????????????????
  #       ????????????????
  #       ????????????????
  #       ????????????????
  #       ????????????????
  #     sw                se
  #
  # And so it goes. The relationship becomes clear if we stop thinking about generations and sizes and
  # start thinking about the binary logarithm of generations and sizes. For historical reasons, the binary
  # logarithm of the length of a side of a square is called its **level**.

  # 2x2 squares are level 1. 4x4 squares are level 2. In other words, the level of a square is the level of
  # its component quadrants plus one. This sets up a recursion which amounts to counting the squares in a
  # path from our subject square to its component cells.
  YouAreDaChef(Square)
    .after 'initialize', ->
      @level = @nw.level + 1

  # Cells are level zero, which terminates the recursion.
  _.extend Cell.prototype,
    level:
      0

  # In a moment we'll give the method for doubling the size of a square and moving it forward into the future,
  # very much in the style of obtaining a cell's `result`, and not suprisingly using results to compute its future.
  # But first, let's determine how far forward in time doubling a square moves it.
  #
  # A square of size two moves one generation forward. A square of size four moves two generations forward. A
  # square of size eight moves four generations forward. More simply:
  #
  # **A square of level `L` moves 2^(L-1) generations forward in time and doubles in size**.
  #
  # This is exactly the same relationship a square has to its `result`: The result of a square is 2^(L-1)
  # generations forward in time.
  #
  # Results and futures are inverses of each other. The result of a square is a smaller square forward in time that
  # we can know regardless of what lies outside of the square. The future of a square is a larger square forward
  # in time that we can know given that only empty space lies outside the square.
  #
  # The difference is that a result square has a level of `L-1` and a future has a level of `L+1`.

  # ### Calculating the immediate future
  #
  # Let's start with a diagram for determining the future of a square:
  #
  # Given (the `?` stands for a cell or square):
  #
  #     nw  ne
  #       ??
  #       ??
  #     sw  se
  #
  # We want:
  #
  #     nw    ne
  #       ????
  #       ????
  #       ????
  #       ????
  #     sw    se
  #
  # Borrowing from our technique for computing results, we want to find some squares with results we can stitch together
  # to make our future square. So let's build our future square. Consider these four squares. In each one, we have duplicated
  # our square in one of its corners and filled the remainder with empty squares the same size as our square:
  #
  #     nw         ne
  #       ....|....
  #       ....|....
  #       ..??|??..
  #       ..??|??..
  #       ----+----
  #       ..??|??..
  #       ..??|??..
  #       ....|....
  #       ....|....
  #     sw         se

  # We're redy to use this diagram to write our method. First, here's our code for making empty squares:
  _.extend Square.prototype,
    empty_copy: ->
      empty_quadrant = @nw.empty_copy()
      Square.cache.canonicalize_by_quadrant
        nw: empty_quadrant
        ne: empty_quadrant
        se: empty_quadrant
        sw: empty_quadrant

  _.extend Cell.prototype,
    empty_copy: ->
      Cell.Dead

  # Here's our method:
  _.extend Square.prototype,
    future: ->

      # an empty copy of our square
      vacant = @empty_copy()

      # Let's make the four squares diagrammed above
      four_squares =
        nw: Square.cache
          .canonicalize_by_quadrant
            nw: vacant
            ne: vacant
            se: this
            sw: vacant
        ne: Square.cache
          .canonicalize_by_quadrant
            nw: vacant
            ne: vacant
            se: vacant
            sw: this
        se: Square.cache
          .canonicalize_by_quadrant
            nw: this
            ne: vacant
            se: vacant
            sw: vacant
        sw: Square.cache
          .canonicalize_by_quadrant
            nw: vacant
            ne: this
            se: vacant
            sw: vacant

      # Let's take their results:
      #
      #     nw         ne
      #       ....|....
      #       .++.|.++.
      #       .++.|.++.
      #       ....|....
      #       ----+----
      #       ....|....
      #       .++.|.++.
      #       .++.|.++.
      #       ....|....
      #     sw         se
      four_results =
        nw: four_squares.nw.result()
        ne: four_squares.ne.result()
        se: four_squares.se.result()
        sw: four_squares.sw.result()

      # Consider those results relative to the original square.
      # let's redraw the diagram, but this time we'll have everything overlap.
      #
      # Here're the four squares again in two diagrams:
      #
      #     nw      ne  nw      ne
      #       ....          ....
      #       ....          ....
      #       ..??..      ..??..
      #       ..??..      ..??..
      #         ....      ....
      #         ....      ....
      #     sw      se  sw      se
      #
      # Now we draw the results of those four:
      #
      #     nw      ne  nw      ne
      #       ....          ....
      #       .nw.          .ne.
      #       .nw...      ...ne.
      #       ...se.      .sw...
      #         .se.      .sw.
      #         ....      ....
      #     sw      se  sw      se
      #
      # And superimpose those results:
      #
      #     nw    ne
      #       nwne
      #       nwne
      #       swse
      #       swse
      #     sw    se

      # Presto! Our four results are the future square we're after!
      Square.cache
        .canonicalize_by_quadrant(four_results)


  # ### Import and export

  # `to_json` and `toString` are simple methods for cells.
  _.extend Cell.prototype,
    to_json: ->
      [@value]
    toString: ->
      '' + @value

  # `to_json` and `toString` are memoized methods for squares
  YouAreDaChef(Square)
    .after 'initialize', ->
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
      @toString = _.memoize( ->
        (_.map @to_json(), (row) ->
          ([' ', '*'][c] for c in row).join('')
        ).join('\n')
      )

  # ### Making copies of squares
  #
  # For calculating the future of a square containing a pattern, we often need to make a larger square with the
  # current square centered surrounded by empty squares. We also need to trim such a square to a smaller size,
  # discarding the borders.

  # A core requirement is to make an empty copy of a cell or square. In effect, we are making an empty
  # square of the same size.
  _.extend Cell.prototype,
    empty_copy: ->
      Cell.Dead

  # We don't bother memoizing this method for squares, we are already taking advantage of redundancy.
  _.extend Square.prototype,
    empty_copy: ->
      empty_quadrant = @nw.empty_copy()
      Square.cache.canonicalize_by_quadrant
        nw: empty_quadrant
        ne: empty_quadrant
        se: empty_quadrant
        sw: empty_quadrant

    # Given the ability to make an empty copy, we can now resize squares to any size. We start with methods to inflte and deflate
    # squares, and implement resizing a square with them.

    # Find or create a smaller square centered on this square
    crop_by: (extant) ->
      return this if extant is 0
      Square.cache.canonicalize_by_quadrant(
        _.reduce [0..(extant - 1)], (quadrants) ->
          nw: quadrants.nw.se
          ne: quadrants.ne.sw
          se: quadrants.se.nw
          sw: quadrants.sw.ne
        , this
      )

    # Find or create a larger square centered on this square with
    # the excess composed of empty squares
    pad_by: (extant) ->
      if extant is 0
        return this
      else
        empty_quadrant = @nw.empty_copy()
        Square.cache
          .canonicalize_by_quadrant
            nw: Square.cache.canonicalize_by_quadrant
              nw: empty_quadrant
              ne: empty_quadrant
              se: @nw
              sw: empty_quadrant
            ne: Square.cache.canonicalize_by_quadrant
              nw: empty_quadrant
              ne: empty_quadrant
              se: empty_quadrant
              sw: @ne
            se: Square.cache.canonicalize_by_quadrant
              nw: @se
              ne: empty_quadrant
              se: empty_quadrant
              sw: empty_quadrant
            sw: Square.cache.canonicalize_by_quadrant
              nw: empty_quadrant
              ne: @sw
              se: empty_quadrant
              sw: empty_quadrant
          .pad_by(extant - 1)

    # Resize to a given level
    resize_to: (level) ->
      this_level = @level
      if level > this_level
        @pad_by(level - this_level)
      else if level < this_level
        @crop_by(this_level - level)
      else
        this