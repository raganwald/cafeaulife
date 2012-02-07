Life = require('../../lib/cafeaulife')
Life.Square.set_universe_rules [2,3],[3]

r_pentomino = Life.Square.find_or_create [
  [0, 0, 0, 0]
  [0, 1, 0, 0]
  [1, 1, 1, 0]
  [0, 0, 1, 0]
]

( (start = r_pentomino, inflation = 8) ->

  board = start.pad_by(inflation)

  console?.log "#{board.generations} generations:\n\n#{board.result().crop_by(2)}"

)()