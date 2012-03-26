# This module is part of [recursiveuniver.se](http://recursiveuniver.se).
#
# ## Cache Module
#
# HashLife uses extensive [canonicalization][canonical] to optimize the storage of very large patterns with repetitive
# components. The Cache Module implements a very naive hash-table for canoncial representations of squares.
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

# ### Implementing the cache
#
# The cache is organized into an array of 'buckets', each of which is a hash from a simple key
# to a cached square. The buckets are organized by level of the square. This allows some simple
# ordering later when we start fooling around with garbage collection: It's easy to find the
# largest squares that aren't in use.
exports.mixInto = ({Square, Cell}) ->

  counter = 0

  YouAreDaChef(Cell)
    .after 'initialize', ->
      @id = (counter += 1)

  YouAreDaChef(Square)
    .after 'initialize', ->
      @id = (counter += 1)

  _.extend Square,

    cache:

      buckets: []

      clear: ->
        @buckets = []

      length: 0

      find: ({nw, ne, se, sw}) ->
        console.trace() unless nw?.level?
        (@buckets[nw.level + 1] ||= {})["#{nw.id}-#{ne.id}-#{se.id}-#{sw.id}"]

      add: (square) ->
        @length += 1
        {nw, ne, se, sw} = square
        (@buckets[nw.level + 1] ||= {})["#{nw.id}-#{ne.id}-#{se.id}-#{sw.id}"] = square

    canonicalize: (quadrants) ->
      found = @cache.find(quadrants)
      if found
        found
      else
        @cache.add(new Square.RecursivelyComputable(quadrants))

# ## The first time through
#
# If this is your first time through the code, and you've already read the [Rules][rules] and [Future][future] modules, you can look at the
# [Garbage Collection][gc] and [API][api] modules next.
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