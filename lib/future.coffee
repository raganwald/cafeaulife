# This module is part of [recursiveuniver.se](http://recursiveuniver.se).
#
# ## Future Module
#
# The Future Module provides methods for computing the future of a pattern, taking into account its ability to grow beyond
# the size of its container square.

# ### The Life "Universe"
#
# This module mixes special case functionality for computing the `future` of a square into `Square` and `Cell`.

# ### Baseline Setup
_ = require('underscore')
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
  # Now let's consider a square of size eight (or larger). For the moment, we can ignore the question of what happens
  # when a square is not in the cache, because when dealing with squares of size eight, we only ever need
  # to look up squares of size four, and they are all seeded in the cache. (Once we have established how
  # to construct the result for a square of size eight, including its result and velocity, we will be able
  # to write out `.find` method to handle looking up squares of size eight and dealing with cache 'misses'
  # by constructing a new square.)

  # Here's our class for recursively computible squares. We'll actually use this for all squares we build on the fly.
  class Square.RecursivelyComputable extends Square

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
    #
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
    # We will see below the exact mechanism for extracting the results, the important thing for the moment is
    # the idea that we have four squares 'built in' that we're going to use to get those results.
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
    #
    # Given this basic pattern, let's see how we actually do it.

    # ### Making a Square from an Intermediate Square
    #
    # We start with a function that maps a square to the nine sub-squares of an intermediate square
    @square_to_intermediate_map: (square) ->
      nw: square.nw
      ne: square.ne
      se: square.se
      sw: square.sw
      nn:
        nw: square.nw.ne
        ne: square.ne.nw
        se: square.ne.sw
        sw: square.nw.se
      ee:
        nw: square.ne.sw
        ne: square.ne.se
        se: square.se.ne
        sw: square.se.nw
      ss:
        nw: square.sw.ne
        ne: square.se.nw
        se: square.se.sw
        sw: square.sw.se
      ww:
        nw: square.nw.sw
        ne: square.nw.se
        se: square.sw.ne
        sw: square.sw.nw
      cc:
        nw: square.nw.se
        ne: square.ne.sw
        se: square.se.nw
        sw: square.sw.ne

    # In order to work on our intermediate square, we want to map functions across all of its keys, such
    # as canonicalizing each value, taking the result of each value, or taking the result at a certain time
    # in the future. We'll derive those methods later, for now we hand-wave that they exist.
    @map_fn: (fn) ->
      (parameter_hash) ->
        _.reduce parameter_hash, (acc, value, key) ->
          acc[key] = fn(value)
          acc
        , {}

    @take_the_canonicalized_values: @map_fn(
      (quadrants) ->
        Square.canonicalize(quadrants)
    )

    @take_the_results: @map_fn(
      (square) ->
        square.result()
    )

    @take_the_results_at_time: (t) ->
      @map_fn(
        (square) ->
          square.result_at_time(t)
      )

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
    # As you'll see below, we use `take_the_results` or `take_the_results_at_time(t)`
    @intermediate_to_subsquares_map: (intermediate_square) ->
      nw:
        nw: intermediate_square.nw
        ne: intermediate_square.nn
        se: intermediate_square.cc
        sw: intermediate_square.ww
      ne:
        nw: intermediate_square.nn
        ne: intermediate_square.ne
        se: intermediate_square.ee
        sw: intermediate_square.cc
      se:
        nw: intermediate_square.cc
        ne: intermediate_square.ee
        se: intermediate_square.se
        sw: intermediate_square.ss
      sw:
        nw: intermediate_square.ww
        ne: intermediate_square.cc
        se: intermediate_square.ss
        sw: intermediate_square.sw

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

    # We now define some initialization for a recursively computible square,
    # starting with the result and including some memoized intermediate results
    # that speed things up for us.
    #
    # The memoizing is a little more bespoke than you would usually see. Normally,
    # you would use something like;
    #
    #   @some_memoized_method = _.memoize( ->
    #     "method_body_goes_here"
    #   )
    #
    # However, rolling our own memoize infrastructure allows us to construct
    # the `children` method that shows us which squares are logically related to any given
    # square, by dint of being its quadrants or result at any time in the future
    initialize: ->
      super()
      @memoized = {}

    @memoize: (name, method_body) ->
      (args...) ->
        index = name + _.map( args, (arg) -> "_#{arg}" ).join('')
        @get_memo(index) or @set_memo(index, method_body.call(this, args...))

    get_memo: (index) ->
      @memoized[index]

    set_memo: (index, square) ->
      @memoized[index] = square

    # We now have everything we need to compute the
    # result of any square of size eight or larger, any time in the future from time `T+1` to time `T+2^(n-1)`
    # where `n` is the level of the square.
    #
    # The naïve result is obtained as follows: We construct an intermediate square from subresults (moving
    # forward to `T+2^(n-2)`), and then we obtain its overlapping squares and take *their* results (moving
    # forward `2^(n-2)` again, for a total advance of `2^(n-1)`).
    #
    # The only complication is that we memoize the result for performance... This is HashLife after all, and we
    # do not like to repeat ourselves in either Space or Time.
    #
    # Of course, there's another refinement: Instead of naïvely writinga method, we take our mapping functions
    # from above and chain them together with the `sequence` method. `_.compose(f, g, h)(x)` -> `f(g(h(x)))`,
    # whereas `sequence(f, g, h)(x)` -> `h(g(f(x)))`. That doesn't look like much, but a better way to put it is:
    #
    #   (x) ->
    #     _temp = f(x)
    #     _temp = g(_temp)
    #     _temp = h(_temp)
    #     _temp
    #
    # In other words, `sequence` is a poor man's monad. It behaves like just writing a function line by line, but it does
    # allow us to refactor the way we glue these algorithms together later if we want. For example (hint, hint) if we
    # wanted to do a little garbage collection of the cache, we could patch the way `sequence` works without having to rewrite
    # any of the functions `sequence` glues together.
    @sequence: (fns...) ->
      _.compose(fns.reverse()...)

    result:
      @memoize 'result', ->
        Square.canonicalize(
          Square.RecursivelyComputable.sequence(
            Square.RecursivelyComputable.square_to_intermediate_map
            Square.RecursivelyComputable.take_the_canonicalized_values
            Square.RecursivelyComputable.take_the_results
            Square.RecursivelyComputable.intermediate_to_subsquares_map
            Square.RecursivelyComputable.take_the_canonicalized_values
            Square.RecursivelyComputable.take_the_results
          )(this)
        )

    # What if we don't want to move so far forward in time? Well, we don't have to. First, let's assume that
    # we have a method called `result_at_time`. If that's the case, when we generate an intermediate square,
    # we can generate one that is less than `2^(n-2)` generations forward:

    # Armed with this one additional function, we can write a general method for determining the result
    # of a square at an arbitrary point forward in time. Modulo some error checking, we check and see whether
    # we are moving forward more or less than half as much as the maimum amount. If it's more than half, we
    # start by generating the intermediate square from results. If it's less than half, we start by generating
    # the intermediate squre by cropping.
    #
    # These are methods on squares and not just recursively computible squares, because they need to work on
    # squares of level 1 and 2.
    result_at_time:
      @memoize 'result_at_time', (t) ->
        if t is 0
          Square.canonicalize
            nw: @nw.se
            ne: @ne.sw
            se: @se.nw
            sw: @sw.ne
        else if t <= Math.pow(2, @level - 3)
          Square.canonicalize(
            Square.RecursivelyComputable.sequence(
              Square.RecursivelyComputable.square_to_intermediate_map
              Square.RecursivelyComputable.take_the_canonicalized_values
              Square.RecursivelyComputable.take_the_results_at_time(t)
              Square.RecursivelyComputable.intermediate_to_subsquares_map
              Square.RecursivelyComputable.take_the_canonicalized_values
              Square.RecursivelyComputable.take_the_results_at_time(0)
            )(this)
          )
        else if Math.pow(2, @level - 3) < t < Math.pow(2, @level - 2)
          Square.canonicalize(
            Square.RecursivelyComputable.sequence(
              Square.RecursivelyComputable.square_to_intermediate_map
              Square.RecursivelyComputable.take_the_canonicalized_values
              Square.RecursivelyComputable.take_the_results
              Square.RecursivelyComputable.intermediate_to_subsquares_map
              Square.RecursivelyComputable.take_the_canonicalized_values
              Square.RecursivelyComputable.take_the_results_at_time(t - Math.pow(2, @level - 3))
            )(this)
          )
        else if t is Math.pow(2, @level - 2)
          @result()
        else if t > Math.pow(2, @level - 2)
          throw "I can't go further forward than #{Math.pow(2, @level - 2)}"

  Square.Seed::result_at_time = (t) ->
    if t is 0
      Square.canonicalize
        nw: @nw.se
        ne: @ne.sw
        se: @se.nw
        sw: @sw.ne
    else if t is 1
      @result()
    else if t > 1
      throw "I can't go further forward than #{Math.pow(2, @level - 2)}"

  # ## Computing the future of a square
  #
  # Let's say we have a square and we wish to determine its future at time `t`.
  # We calculate the smallest square that could possible contain its future, taking
  # into account that the pattern in the square could grow once cell in each direction
  # per generation.
  #
  # We take our square and 'pad' it with empty squares until it is large enough to
  # contain its future. We then double that square and embed our pattern in the center. This becomes our base
  # square: It's our square embdedded in a possible vast empty square. We then take the
  # base square's `result_at_time(t)` which gives us the future of our pattern.
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
# If this is your first time through the code, and you've already read the [Rules Module][rules], you can look at the [Cache][cache],
# [Garbage Collection][gc], and [API][api] modules.
#
# [menagerie]: http:menagerie.html
# [api]: http:api.html
# [future]: http:future.html
# [cache]: http:cache.html
# [canonical]: https://en.wikipedia.org/wiki/Canonicalization
# [rules]: http:rules.html
# [gc]: http:gc.html

# ---
#
# **(c) 2012 [Reg Braithwaite](http://braythwayt.com)** ([@raganwald](http://twitter.com/raganwald))
#
# Cafe au Life is freely distributable under the terms of the [MIT license](http://en.wikipedia.org/wiki/MIT_License).
#
# The annotated source code was generated directly from the [original source][source] using [Docco][docco].
#
# [source]: https://github.com/raganwald/cafeaulife/blob/master/lib
# [docco]: http://jashkenas.github.com/docco/