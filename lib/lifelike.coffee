_ = require('underscore')
C = require('./cafeaulife')

root = this

#########
# Seeds #
#########

# a handy function for generatimg cartesian products of a range

cartesian_product = (range) ->
  _.reduce(
    _.reduce(
      _.reduce( [a,b,c,d] for a in range for b in range for c in range for d in range
      , (x, y) -> x.concat(y))
    , (x, y) -> x.concat(y))
  , (x, y) -> x.concat(y))

dfunc = (dictionary) ->
  (indices...) ->
    _.reduce indices, (a, i) ->
      a[i]
    , dictionary

_.defaults root,
  generate_seeds_from_rule: (survival, birth) ->
    rule = dfunc [
      (if birth.indexOf(x) >= 0 then C.Cell.Alive else C.Cell.Dead) for x in [0..9]
      (if survival.indexOf(x) >= 0 then C.Cell.Alive else C.Cell.Dead) for x in [0..9]
    ]

    class SquareSz4 extends C.Square
      constructor: (params) ->
        super(params)
        @generations = 1
        @result = _.memoize(
          ->
            a = @.to_json()
            succ = (row, col) ->
              count = a[row-1][col-1] + a[row-1][col] + a[row-1][col+1] + a[row][col-1] +
                      a[row][col+1] + a[row+1][col-1] + a[row+1][col] + a[row+1][col+1]
              rule(a[row][col], count)
            C.Square.find_or_create
              nw: succ(1,1)
              ne: succ(1,2)
              se: succ(2,2)
              sw: succ(2,1)
        )

    # precompute all 65K SquareSz4s so that the algorithm for recursively genrating results
    # terminates when it reaches a size four square

    cartesian_product(

      # ...from all sixteen possible size twos
      cartesian_product([C.Cell.Dead, C.Cell.Alive]).map ([nw, ne, se, sw]) ->
        _.tap new C.Square({nw, ne, se, sw}), (sq) ->
          C.Square.add(sq) unless C.Square.find({nw, ne, se, sw})

    ).forEach ([nw, ne, se, sw]) ->
      C.Square.add(new SquareSz4({nw, ne, se, sw})) unless C.Square.find({nw, ne, se, sw})