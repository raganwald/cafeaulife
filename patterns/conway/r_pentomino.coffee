Life = require('../../lib/cafeaulife')
Life.Square.set_universe_rules [2,3],[3]

r_pentomino = Life.Square.from_json [
  [0, 0, 0, 0]
  [0, 1, 0, 0]
  [1, 1, 1, 0]
  [0, 0, 1, 0]
]

( (start = r_pentomino, time = 8) ->

  board = start.fast_forward_to_level(time).trim()

  console?.log board.result().toString()

)()