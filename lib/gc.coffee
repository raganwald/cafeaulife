# This module is part of [resursiveuniver.se](http://recursiveuniver.se).
#
# ## Garbage Collection Module
#
# HashLife uses extensive [canonicalization][canonical] to optimize the storage of very large patterns with repetitive
# components. The Cache Module implementss a very naive hash-table for canoncial representations of squares.
#
# [cache]: http:cache.html
# [canonical]: https://en.wikipedia.org/wiki/Canonicalization

# ### Canoncialization: The "Hash" in HashLife
#
# Cafe au Life can calculate the future of many highly repetitive patterns without garbage collection, it simply
# caches all of its results as it goes along. That's blisteringly fast. However, patterns with a lot of entropy
# can quickly fill up the cache. On my development machine, Node blows up some time after the cache hits 700,000
# squares.
#
# By way of comparison, Cafe au Life can calulate the future of a glider gun out to [quadrillions of generations][b]
# with a population of 23,900,000,000,000,036 live cells,
# but the rabbits [methuselah][m] blows the cache up before it can stabilize with a population of 1,744 live cells
# at 17,331 generations.
#
# [b]: http://raganwald.posterous.com/a-beautiful-algorithm
# [m]: http://www.conwaylife.com/wiki/index.php?title=List_of_long-lived_methuselahs
#
# The size of the pattern and the length of the simulation are not the limiting factor, it's the entropy that counts.
# Or if you prefer, the time complexity. To handle patterns like 'rabbits,' we need to garbage collect the cache when
# it gets too big.
#
# This module implements a simple reference-counting scheme and cache garbage collector. It provides a `mixInto` function\
# so that it retroactively modify existing classes.

# ### Baseline Setup
_ = require('underscore')
YouAreDaChef = require('YouAreDaChef').YouAreDaChef
exports ?= window or this

exports.mixInto = ({Square, Cell}) ->

  # ### Reference Counting
  #
  # The basic principle is that a square's reference count is the number of squares in the cache that
  # refer to the square. So when we add a square to the cache, we increment the reference count for its children.
  # When we remove a square from the cache, we decrement the reference count for its children.
  #
  # There is a little bookkeeping involved with squares that memoize results, because we must increment their new children
  # on the fly. And we never garbage collect cells, level 1, or level 2 squares (the smallest and seed squares respectively).
  _.extend Square.cache,
    old_add = Square.cache.add

    add: (square) ->
      _.each square.children(), (v) ->
        v.incrementReference()
      old_add.call(this, square)

    remove: (square) ->
      @length -= 1
      delete (@buckets[square.nw.level + 1] ||= {})["#{square.nw.id}-#{square.ne.id}-#{square.se.id}-#{square.sw.id}"]
      square

  _.extend Cell.prototype,
    has_references: ->
      true
    has_no_references: ->
      false
    has_one_reference: ->
      false
    has_many_references: ->
      true
    incrementReference: ->
      this
    decrementReference: ->
      this
    children: -> {}
    remove: ->
    removeRecursively: ->


  _.extend Square.Smallest.prototype,
    has_references: ->
      true
    has_no_references: ->
      false
    has_one_reference: ->
      false
    has_many_references: ->
      true
    incrementReference: ->
      this
    decrementReference: ->
      this
    children: -> {}
    remove: ->
    removeRecursively: ->

  _.extend Square.Seed.prototype,
    has_references: ->
      true
    has_no_references: ->
      false
    has_one_reference: ->
      false
    has_many_references: ->
      true
    incrementReference: ->
      this
    decrementReference: ->
      this
    children: -> {}
    remove: ->
    removeRecursively: ->

  # ### Modifying `Square.RecursivelyComputable`
  #
  # We take advantage of the way `Square.RecursivelyComputable` is factored to introduce reference
  # counting and add methods to remove a recursively computable square from the cache.
  YouAreDaChef(Square.RecursivelyComputable)
    .after 'initialize', ->
      @references = 0
    .before 'set_memo', (index) ->
      if (existing = @get_memo(index))
        existing.decrementReference()
    .after 'set_memo', (index, square) ->
      square.incrementReference()

  _.extend Square.RecursivelyComputable.prototype,
    has_references: ->
      @references > 0
    has_no_references: ->
      @references is 0
    has_one_reference: ->
      @references is 1
    has_many_references: ->
      @references > 1
    incrementReference: ->
      throw "incrementReference!? #{@references}" unless @references >= 0
      @references += 1
      this
    decrementReference: () ->
      throw "decrementReference!?" unless @references > 0
      @references -= 1
      this

    children: ->
      _.extend {nw: @nw, ne: @ne, se: @se, sw: @sw}, @memoized

    remove: ->
      if @references is 0
        Square.cache.remove(this)
        _.each @children(), (v) ->
          v.decrementReference()

    removeRecursively: ->
      if @references is 0
        Square.cache.remove(this)
        _.each @children(), (v) ->
          v.decrementReference()
          v.removeRecursively()


  # ### Naïve Garbage Collection
  #
  # Our GC is pretty bone-headed, it uses brute force to get a list of
  # removeable squares, then marches through them from highest to lowest
  # level, recursively removing them and any children freed up by removing them.
  _.extend Square.cache,
    removeablesByLevel: ->
      _.map @buckets, (bucket) ->
        if (bucket)
          _.select( _.values(bucket), (sq) -> sq.has_no_references() )
        else
          []

    removeables: ->
      _.reduce @removeablesByLevel().reverse(), (re, level) ->
        re = re.concat( level )
      , []

    full_gc: ->
      _.each @removeables(), (sq) ->
        sq.removeRecursively()

    resize: (from, to) ->
      if Square.cache.length >= from
        old = Square.cache.length
        r = @removeables()
        i = 0
        while i < r.length and Square.cache.length > to
          r[i].removeRecursively()
          i += 1
        console?.log "GC: #{old}->#{Square.cache.length}" if to > 0

    # ### Pinning squares
    #
    # So far, so good. But there is a flaw of sorts. When do we garbage collect?
    # And when we do garbage collect, what happens to intermediate results we're
    # using in the middle of calculating the future of a pattern?
    #
    # What we do is rewrite `Square.RecursivelyComputable.sequence` such that it
    # increments the references of squares passed in as a `parameter_hash`, and
    # decrements them when it's finished. This works recursively, so if at any time in
    # the middle of a computation we need to garbage collect, we can do it with
    # the confidence that we won't remove anything we're using.
    #
    # This means some care must be taken in the way `result` and `result_at_time(t)`
    # are written, such as always using `sequence` and a `parameter_hash`.
    each_leaf = (h, fn) ->
      _.each h, (value) ->
        if value instanceof Square
          fn(value)
        else if value.nw instanceof Square
          fn(value.nw)
          fn(value.ne)
          fn(value.se)
          fn(value.sw)

    sequence: (fns...) ->
      _.compose(
        _(fns).map( (fn) ->
            (parameter_hash) ->
              each_leaf(parameter_hash, (sq) -> sq.incrementReference())
              Square.cache.resize(700000, 350000)
              _.tap fn(parameter_hash), ->
                each_leaf(parameter_hash, (sq) -> sq.decrementReference())
          ).reverse()...
      )

  "garbage collection can be disabled by commenting this line out"
  Square.RecursivelyComputable.sequence = Square.cache.sequence

# ---
#
# **(c) 2012 [Reg Braithwaite](http://raganwald.com)** ([@raganwald](http://twitter.com/raganwald))
#
# Cafe au Life is freely distributable under the terms of the [MIT license](http://en.wikipedia.org/wiki/MIT_License).
#
# The annotated source code was generated directly from the [original source][source] using [Docco][docco].
#
# [source]: https://github.com/raganwald/cafeaulife/blob/master/lib
# [docco]: http://jashkenas.github.com/docco/