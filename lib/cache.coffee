# This module is part of [resursiveuniver.se](http://recursiveuniver.se).
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

# ### Implementing the cache
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
        @cache.add(new Square.RecursivelyComputable(quadrants))

  # ### Reference Counting
  #
  # The basic principle is that a square's reference count is the number of squares in the cache that
  # refer to the square.

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
    remove: ->
    removeRecursively: ->

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
    decrementReference: ->
      throw "decrementReference!? #{@references}" unless @references > 0
      @references -= 1
      this

    children: ->
      [@nw, @ne, @se, @sw].concat @get_all_memos()

    remove: ->
      if @references is 0
        Square.cache.remove(this)
        _.each @children(), (c) ->
          c.decrementReference()
    removeRecursively: ->
      if @references is 0
        Square.cache.remove(this)
        _.each @children(), (c) ->
          c.decrementReference()
          c.removeRecursively()

  old_add = Square.cache.add

  _.extend Square.cache,
    removeables: ->
     _(@buckets).chain()
      .values()
      .select( (sq) -> sq.has_no_references() )
      .value()

    remove: (square) ->
      delete @buckets["#{square.nw.id}-#{square.ne.id}-#{square.se.id}-#{square.sw.id}"]
      square

    add: (square) ->
      {nw, ne, se, sw} = square
      nw.incrementReference()
      ne.incrementReference()
      se.incrementReference()
      sw.incrementReference()
      old_add.call(this, square)

    full_gc: ->
      _.each @removeables(), (sq) -> sq.removeRecursively()

    sequence: (fns...) ->
      _.compose(
        _(fns)
          .chain()
          .map( (fn) ->
            (h) ->
              {input_incremented, params} = _.reduce h, (acc, value, key) ->
                {input_incremented, params} = acc
                if value instanceof Cell
                  params[key] = value
                else if value instanceof Square
                  unless Square.cache.find(value)
                    throw "unexpected: square that is not in the cache"
                  input_incremented.push value
                  value.incrementReference()
                  params[key] = value
                else
                  {nw, ne, se, sw} = value
                  params[key] = value
                  if nw? and ne? and se? and sw?
                    _.each {nw, ne, se, sw}, (subvalue, subkey) ->
                      if subvalue instanceof Square
                        unless Square.cache.find(subvalue)
                          throw "unexpected: square that is not in the cache"
                        input_incremented.push subvalue
                        subvalue.incrementReference()
                {input_incremented, params}
              , {input_incremented: [], params: {}}
              _.tap fn(params), (result_map) ->
                _.each input_incremented, (sq) ->
                  if sq.references <= 0 then console?.log "post-decrementing #{sq.references}"
                  sq.decrementReference()
          )
          .value()
          .reverse()...
      )

  Square.RecursivelyComputable.sequence = Square.cache.sequence

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