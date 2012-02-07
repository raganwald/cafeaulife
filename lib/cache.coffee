# ## Memoizing: The "Hash" in HashLife
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

# Cafe au Life uses [Underscore.js][u] extensively:
#
# [u]: http://documentcloud.github.com/underscore/
_ = require('underscore')

# YouAreDaChef provides a nice clean set of semantics for AOP
YouAreDaChef = require('YouAreDaChef').YouAreDaChef

# ### Mix the functionality into `Square`, `RecursivelyComputableSquare`, and `Cell`

exports.mixInto = ({Square, RecursivelyComputableSquare, Cell}) ->

  # ### Extending Cell and Square
  #
  # We add some support for hashing to cells and squares.

  # Initialize a cell's hash property to the cell's numeric value
  YouAreDaChef(Cell)
    .after 'initialize', ->
      @hash = @value

  # Initialize a square's hash property to the cache's has function
  YouAreDaChef(Square)
    .after 'initialize', ->
      @hash = Square.cache.hash(this)

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