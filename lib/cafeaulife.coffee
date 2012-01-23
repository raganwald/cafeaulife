_ = require('underscore')

root = this

#########################
# The Grand-daddy class #
#########################

class Square
  constructor: ->
    @toString = _.memoize( ->
      (_.map @to_json(), (row) ->
        (_.map row, (cell) ->
          if cell then '*' else ' '
        ).join('')
      ).join('\n')
    )

###########################################
# Indivisibles represent individual cells #
###########################################

class Indivisible extends Square
  constructor: (@hash) ->
  toValue: ->
    @hash
  to_json: ->
    [@hash]
  level: ->
    0
  empty_copy: ->
    Indivisible.Dead

Indivisible.Alive = _.tap new Indivisible(1), (alive) ->
  alive.is_empty = ->
    false
Indivisible.Dead = _.tap new Indivisible(0), (dead) ->
  dead.is_empty = ->
    true

##################################################################################
# Divisible is the parent for Size two, four, and larger ("non-trivial") squares #
##################################################################################

id = 0

class Divisible extends Square
  constructor: (params) ->
    super()
    {@nw, @ne, @se, @sw} = params
    @hash = cache.hash(this)
    @id = (id += 1)
    @is_empty = _.memoize( ->
      @nw.is_empty() and @ne.is_empty() and @se.is_empty() and @sw.is_empty()
    )
    @to_json = _.memoize( ->
      a =
        nw: @nw.to_json()
        ne: @ne.to_json()
        se: @se.to_json()
        sw: @sw.to_json()
      b =
        top: _.map( _.zip(a.nw, a.ne), (row) ->
          [left, right] = row
          if _.isArray(left)
            left.concat(right)
          else
            row
        )
        bottom: _.map( _.zip(a.sw, a.se), (row) ->
          [left, right] = row
          if _.isArray(left)
            left.concat(right)
          else
            row
        )
      b.top.concat(b.bottom)
    )
  level: ->
    @nw.level() + 1
  empty_copy: ->
    empty_quadrant = @nw.empty_copy()
    cache.find_or_create_by_quadrant
      nw: empty_quadrant
      ne: empty_quadrant
      se: empty_quadrant
      sw: empty_quadrant
  deflate_by: (extant) ->
    return this if extant is 0
    cache.find_or_create_by_quadrant(
      _.reduce [0..(extant - 1)], (quadrants) ->
        nw: quadrants.nw.se
        ne: quadrants.ne.sw
        se: quadrants.se.nw
        sw: quadrants.sw.ne
      , this
    )
  inflate_by: (extant) ->
    if extant is 0
      return this
    else
      empty_quadrant = @nw.empty_copy()
      cache
        .find_or_create_by_quadrant
          nw: cache.find_or_create_by_quadrant
            nw: empty_quadrant
            ne: empty_quadrant
            se: @nw
            sw: empty_quadrant
          ne: cache.find_or_create_by_quadrant
            nw: empty_quadrant
            ne: empty_quadrant
            se: empty_quadrant
            sw: @ne
          se: cache.find_or_create_by_quadrant
            nw: @se
            ne: empty_quadrant
            se: empty_quadrant
            sw: empty_quadrant
          sw: cache.find_or_create_by_quadrant
            nw: empty_quadrant
            ne: @sw
            se: empty_quadrant
            sw: empty_quadrant
        .inflate_by(extant - 1)

#####################################################
# Non-Trivial squares are eight and larger in size. #
#####################################################

NonTrivialSquare = do ->

  class IntermediateResult
    constructor: (square) ->
      _.extend this,
        nw: square.nw.result()
        ne: square.ne.result()
        se: square.se.result()
        sw: square.sw.result()
        nn: Square
          .find_or_create_by_quadrant
            nw: square.nw.ne
            ne: square.ne.nw
            se: square.ne.sw
            sw: square.nw.se
          .result()
        ee: Square
          .find_or_create_by_quadrant
            nw: square.ne.sw
            ne: square.ne.se
            se: square.se.ne
            sw: square.se.nw
          .result()
        ss: Square
          .find_or_create_by_quadrant
            nw: square.sw.ne
            ne: square.se.nw
            se: square.se.sw
            sw: square.sw.se
          .result()
        ww: Square
          .find_or_create_by_quadrant
            nw: square.nw.sw
            ne: square.nw.se
            se: square.sw.ne
            sw: square.sw.nw
          .result()
        cc: Square
          .find_or_create_by_quadrant
            nw: square.nw.se
            ne: square.ne.sw
            se: square.se.nw
            sw: square.sw.ne
          .result()
    result: ->
      Square.find_or_create_by_quadrant
        nw: Square
          .find_or_create_by_quadrant
            nw: @nw
            ne: @nn
            se: @cc
            sw: @ww
          .result()
        ne: Square
          .find_or_create_by_quadrant
            nw: @nn
            ne: @ne
            se: @ee
            sw: @cc
          .result()
        se: Square
          .find_or_create_by_quadrant
            nw: @cc
            ne: @ee
            se: @se
            sw: @ss
          .result()
        sw: Square
          .find_or_create_by_quadrant
            nw: @ww
            ne: @cc
            se: @ss
            sw: @sw
          .result()
    to_json: ->
      b =
        top: _.map( _.zip(@nw.to_json(), @nn.to_json(), @ne.to_json()), (row) ->
          _.reduce(row, (acc, cell) ->
            acc.concat(cell)
          , [])
        )
        mid: _.map( _.zip(@ww.to_json(), @cc.to_json(), @ee.to_json()), (row) ->
          _.reduce(row, (acc, cell) ->
            acc.concat(cell)
          , [])
        )
        bot: _.map( _.zip(@sw.to_json(), @ss.to_json(), @sw.to_json()), (row) ->
          _.reduce(row, (acc, cell) ->
            acc.concat(cell)
          , [])
        )
      b.top.concat(b.mid).concat(b.bot)

  class NonTrivialSquare extends Divisible
    constructor: ({nw, ne, se, sw}) ->
      super({nw: nw, ne:ne, se:se, sw:sw})
      @generations = @nw.generations * 2
      me = this
      @intermediate_result = _.memoize( ->
        new IntermediateResult(this)
      )
      @result = _.memoize( ->
        @intermediate_result().result()
      )

#############################################
# Various hash and cache methods for Square #
#############################################

cache = do ->

  num_buckets = 99991 # chosen from http://primes.utm.edu/lists/small/10000.txt. Probably should be > 65K
  buckets = []

  hash = (square_like) ->
    if square_like.hash?
      square_like.hash
    else
      ((3 *hash(square_like.nw)) + (37 * hash(square_like.ne))  + (79 * hash(square_like.se)) + (131 * hash(square_like.sw)))

  find = (quadrants) ->
    bucket_number = hash(quadrants) % num_buckets
    if buckets[bucket_number]?
      _.find buckets[bucket_number], (sq) ->
        sq.nw is quadrants.nw and sq.ne is quadrants.ne and sq.se is quadrants.se and sq.sw is quadrants.sw

  find_or_create_by_quadrant = (quadrants) ->
    found = find(quadrants)
    if found
      found
    else
      add(new NonTrivialSquare(quadrants))

  add = (square) ->
    bucket_number = square.hash % num_buckets
    (buckets[bucket_number] ||= []).push(square)
    square

  bucketed = ->
    _.reduce buckets, (sum, bucket) ->
      sum + bucket.length
    , 0

  histogram = ->
    _.reduce buckets, (histo, bucket) ->
      _.tap histo, (h) ->
        h[bucket.length] ||= 0
        h[bucket.length] += 1
    , []

  find_or_create_by_json = (json) ->
    find_or_create_by_quadrant json_to_quadrants(json)

  find_or_create_by_json = (json) ->
    unless _.isArray(json[0]) and json[0].length is json.length
      throw 'must be a square'
    if json.length is 1
      if json[0][0] instanceof Indivisible
        json[0][0]
      else if json[0][0] is 0
        Indivisible.Dead
      else if json[0][0] is 1
        Indivisible.Alive
      else
        throw 'a 1x1 square must contain a zero, one, or Indivisible'
    else
      half_length = json.length / 2
      find_or_create_by_quadrant
        nw: find_or_create_by_json(
          json.slice(0, half_length).map (row) ->
            row.slice(0, half_length)
        )
        ne: find_or_create_by_json(
          json.slice(0, half_length).map (row) ->
            row.slice(half_length)
        )
        se: find_or_create_by_json(
          json.slice(half_length).map (row) ->
            row.slice(half_length)
        )
        sw: find_or_create_by_json(
          json.slice(half_length).map (row) ->
            row.slice(0, half_length)
        )

  find_or_create = (params) ->
    if _.isArray(params)
      find_or_create_by_json(params)
    else if _.all( ['nw', 'ne', 'se', 'sw'], ((quadrant) -> params[quadrant] instanceof Square) )
      find_or_create_by_quadrant params
    else
      throw "Can't handle #{JSON.stringify(params)}"

  {hash, find, find_or_create, find_or_create_by_quadrant, add, bucketed, histogram}

_.extend Square, cache

_.defaults root, {Square, Indivisible, Divisible, NonTrivialSquare}