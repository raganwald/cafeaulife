_ = require('underscore')

root = this

#########################
# The Grand-daddy class #
#########################

class Square
  constructor: ->

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
  empty: ->
    Indivisible.Dead

Indivisible.Alive = new Indivisible(1)
Indivisible.Dead = new Indivisible(0)

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
  to_json: ->
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
  level: ->
    @nw.level() + 1
  empty: ->
    empty_quadrant = @nw.empty()
    cache.find_or_create_by_quadrant
      nw: empty_quadrant
      ne: empty_quadrant
      se: empty_quadrant
      sw: empty_quadrant
  inflate_by: (extant) ->
    if extant is 0
      return this
    else
      empty_quadrant = @nw.empty()
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

  this_to_intermediate_components = ->
    nw: @nw.result()
    ne: @ne.result()
    se: @se.result()
    sw: @sw.result()
    nn: Square
      .find_or_create_by_quadrant
        nw: @nw.ne
        ne: @ne.nw
        se: @ne.sw
        sw: @nw.se
      .result()
    ee: Square
      .find_or_create_by_quadrant
        nw: @ne.sw
        ne: @ne.se
        se: @se.ne
        sw: @se.nw
      .result()
    ss: Square
      .find_or_create_by_quadrant
        nw: @sw.ne
        ne: @se.nw
        se: @se.sw
        sw: @sw.se
      .result()
    ww: Square
      .find_or_create_by_quadrant
        nw: @nw.sw
        ne: @nw.se
        se: @se.ne
        sw: @se.nw
      .result()
    cc: Square
      .find_or_create_by_quadrant
        nw: @nw.se
        ne: @ne.sw
        se: @se.nw
        sw: @sw.ne
      .result()

  intermediate_components_to_result_components = ->
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

  class NonTrivialSquare extends Divisible
    constructor: ({nw, ne, se, sw}) ->
      super({nw: nw, ne:ne, se:se, sw:sw})
      @velocity = @nw.velocity * 2
      me = this
      @result = _.memoize( ->
        intermediate_square_components = this_to_intermediate_components.call(this)
        result_square_components = intermediate_components_to_result_components.call(intermediate_square_components)
        cache.find_or_create_by_quadrant(result_square_components)
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

root.cafeaulife = {Square, Indivisible, Divisible, NonTrivialSquare}