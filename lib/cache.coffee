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

  Square.cache =

    buckets: {}

    clear: ->
      @buckets = {}

    find: ({nw, ne, se, sw}) ->
      if (a = @buckets[nw.id]) and (b = a[ne.id]) and (c = b[se.id]) then c[sw.id]

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
      {nw, ne, se, sw} = square
      a = (@buckets[nw.id] ||= {})
      b = (a[ne.id] ||= {})
      c = (b[se.id] ||= {})
      c[sw.id] = square

    bucketed: ->
      _.reduce @buckets, (sum, a) ->
        _.reduce a, (sum, b) ->
          _.reduce b, (sum, c) ->
            _.size(c)
          , sum
        , sum
      , 0

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