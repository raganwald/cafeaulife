_ = require('underscore')

C = require('./cafeaulife').cafeaulife

root = this

#########
# Seeds #
#########

C.Indivisible.Alive = new C.Indivisible(1)
C.Indivisible.Dead = new C.Indivisible(0)

# the size four class generates its own result from Life's rules

class SquareSz4 extends C.Divisible
  constructor: (params) ->
    super(params)
    a = @.to_json()
    succ = (row, col) ->
      count = a[row-1][col-1] + a[row-1][col] + a[row-1][col+1] + a[row][col-1] + a[row][col+1] + a[row+1][col-1] + a[row+1][col] + a[row+1][col+1]
      if count is 3 or (count is 2 and a[row][col] is 1) then C.Indivisible.Alive else C.Indivisible.Dead
    @result = C.Square.find_or_create
      nw: succ(1,1)
      ne: succ(1,2)
      se: succ(2,2)
      sw: succ(2,1)
    @velocity = 1

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
  cartesian_product([C.Indivisible.Dead, C.Indivisible.Alive]).map ([nw, ne, se, sw]) ->
    _.tap new C.Divisible({nw, ne, se, sw}), (sq) ->
      C.Square.add(sq) unless C.Square.find({nw, ne, se, sw})

).forEach ([nw, ne, se, sw]) ->
  C.Square.add(new SquareSz4({nw, ne, se, sw})) unless C.Square.find({nw, ne, se, sw})