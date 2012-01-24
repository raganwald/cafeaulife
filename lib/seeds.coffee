_ = require('underscore')
_.defaults this, require('./cafeaulife')

root = this

#########
# Seeds #
#########

Indivisible.Alive = new Indivisible(1)
Indivisible.Dead = new Indivisible(0)

# the size four class generates its own result from Life's rules

class SquareSz4 extends Divisible
  constructor: (params) ->
    super(params)
    @generations = 1
    @result = _.memoize( 
      ->
        a = @.to_json()
        succ = (row, col) ->
          count = a[row-1][col-1] + a[row-1][col] + a[row-1][col+1] + a[row][col-1] +
                  a[row][col+1] + a[row+1][col-1] + a[row+1][col] + a[row+1][col+1]
          if count is 3 or (count is 2 and a[row][col] is 1) then Indivisible.Alive else Indivisible.Dead
        Square.find_or_create
          nw: succ(1,1)
          ne: succ(1,2)
          se: succ(2,2)
          sw: succ(2,1)
    )

# a handy function for generatimg cartesian products of a range

cartesian_product = (range) ->
  _.reduce(
    _.reduce(
      _.reduce( [a,b,c,d] for a in range for b in range for c in range for d in range
      , (x, y) -> x.concat(y))
    , (x, y) -> x.concat(y))
  , (x, y) -> x.concat(y))

# precompute all 65K SquareSz4s so that the algorithm for recursively genrating results
# terminates when it reaches a size four square

cartesian_product(

  # ...from all sixteen possible size twos
  cartesian_product([Indivisible.Dead, Indivisible.Alive]).map ([nw, ne, se, sw]) ->
    _.tap new Divisible({nw, ne, se, sw}), (sq) ->
      Square.add(sq) unless Square.find({nw, ne, se, sw})

).forEach ([nw, ne, se, sw]) ->
  Square.add(new SquareSz4({nw, ne, se, sw})) unless Square.find({nw, ne, se, sw})