# This module is part of [cafeaulife.coffee](http:cafeaulife.html).
#
# ## Cache Module
#
# HashLife uses extensive [canonicalization][canonical] to optimize the storage of very large patterns with repetitive
# components. The Cache Module implementss a very naive hash-table for canoncial representations of squares.
#
# [cache]: http:cache.html
# [canonical]: https://en.wikipedia.org/wiki/Canonicalization

# ### Canoncialization: The "Hash" in HashLife
#
# HashLife gets a tremendous speed-up by storing and reusing squares in a giant cache.
# Any result, at any scale, that has been computed before is reused. This is extremely
# efficient when dealing with patterns that contain a great deal of redundancy, such as
# the kinds of patterns constructed for the purpose of emulating circuits or machines in Life.
#
# Once Cafe au Life has calculated the results for the 65K possible four-by-four
# squares, the rules are no longer applied to any generation: Any pattern of any size is
# recursively computed terminating in a four-by-four square that has already been computed and cached.
#
# This module provides a `mixInto` function so that it retroactively modify existing classes.

# ### Baseline Setup
_ = require('underscore')
YouAreDaChef = require('YouAreDaChef').YouAreDaChef
exports ?= window or this


exports.mixInto = ({Square, RecursivelyComputableSquare, Cell}) ->

  # ### Extending Cell and Square

  counter = 0

  YouAreDaChef(Cell)
    .after 'initialize', ->
      @id = (counter += 1)

  YouAreDaChef(Square)
    .after 'initialize', ->
      @id = (counter += 1)

  _.extend Square,

    cache:

      buckets: {}

      clear: ->
        @buckets = {}

      bucketed: ->
        _.size(@buckets)

      find: ({nw, ne, se, sw}) ->
        @buckets["#{nw.id}-#{ne.id}-#{se.id}-#{sw.id}"]

      add: (square) ->
        {nw, ne, se, sw} = square
        @buckets["#{nw.id}-#{ne.id}-#{se.id}-#{sw.id}"] = square

    canonicalize: (quadrants) ->
      found = @cache.find(quadrants)
      if found
        found
      else
        @cache.add(new RecursivelyComputableSquare(quadrants))

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