_ = require('underscore')

root = this

class Square

class Indivisible extends Square
  constructor: ({@if_alive, @if_dead}) ->
  to_json: ->
    @if_alive( -> [1]) or @if_dead( -> [0])

Alive = new Indivisible
  if_alive: (fn) -> fn.call(this)
  if_dead: (fn) ->

Dead = new Indivisible
  if_alive: (fn) ->
  if_dead: (fn) -> fn.call(this)

class Divisible extends Square
  constructor: ({@nw, @ne, @se, @sw}) ->
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

squares_0 = [Dead, Alive]

squares_1 = [0..15].map (n) ->
  new Divisible
    nw: squares_0[(n&8)>>3]
    ne: squares_0[(n&4)>>2]
    se: squares_0[(n&2)>>1]
    sw: squares_0[n&1]

root.cafeaulife = {Square, Indivisible, Alive, Dead, Divisible}