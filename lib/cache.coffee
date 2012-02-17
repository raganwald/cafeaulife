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
  #
  # We add some support for hashing to cells and squares, then use a *very*
  # naïve cache to hold them.
  YouAreDaChef(Cell)
    .after 'initialize', ->
      @hash = @value

  YouAreDaChef(Square)
    .after 'initialize', ->
      @hash = Square.cache.hash(this)

  Square.cache =

    num_buckets: 7919
    buckets: []

    clear: ->
      @buckets = []

    hash: (square_like) ->
      if square_like.hash?
        square_like.hash
      else
        ((@hash(square_like.nw)) + (3 * @hash(square_like.ne))  + (79 * @hash(square_like.se)) + (37 * @hash(square_like.sw))) % 99991

    hash_string: (square_like) ->
      @hash(square_like).toString()

    find: (quadrants) ->
      bucket_number = @hash(quadrants) % @num_buckets
      if @buckets[bucket_number]?
        _.find @buckets[bucket_number], (sq) ->
          sq.nw is quadrants.nw and sq.ne is quadrants.ne and sq.se is quadrants.se and sq.sw is quadrants.sw

    canonicalize_by_quadrant: (quadrants) ->
      found = @find(quadrants)
      if found
        found
      else
        @add(new RecursivelyComputableSquare(quadrants))

    canonicalize_by_json: (json) ->
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
        @canonicalize_by_quadrant
          nw: @canonicalize_by_json(
            json.slice(0, half_length).map (row) ->
              row.slice(0, half_length)
          )
          ne: @canonicalize_by_json(
            json.slice(0, half_length).map (row) ->
              row.slice(half_length)
          )
          se: @canonicalize_by_json(
            json.slice(half_length).map (row) ->
              row.slice(half_length)
          )
          sw: @canonicalize_by_json(
            json.slice(half_length).map (row) ->
              row.slice(0, half_length)
          )

    canonicalize: (params) ->
      if _.isArray(params)
        @canonicalize_by_json(params)
      else if _.all( ['nw', 'ne', 'se', 'sw'], ((quadrant) -> params[quadrant] instanceof Cell) )
        @canonicalize_by_quadrant params
      else if _.all( ['nw', 'ne', 'se', 'sw'], ((quadrant) -> params[quadrant] instanceof Square) )
        @canonicalize_by_quadrant params
      else
        throw "Cache can't handle #{JSON.stringify(params)}"

    add: (square) ->
      bucket_number = square.hash % @num_buckets
      @buckets[bucket_number] ||= []
      @buckets[bucket_number] = _.reject @buckets[bucket_number], (found) ->
        found.nw is square.nw and found.ne is square.ne and found.se is square.se and found.sw is square.sw
      @buckets[bucket_number].push(square)
      square

    bucketed: ->
      _.reduce @buckets, (sum, bucket) ->
        sum + bucket.length
      , 0

    histogram: ->
      _.reduce @buckets, (histo, bucket) ->
        _.tap histo, (h) ->
          h[bucket.length] ||= 0
          h[bucket.length] += 1
      , []

  Square.canonicalize = (params) ->
    @cache.canonicalize(params)

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