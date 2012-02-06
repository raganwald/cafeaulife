C = require('../../lib/cafeaulife')
C.set_universe_rules [2,3],[3]

r_pentomino = C.Square.find_or_create [
  [0, 0, 0, 0]
  [0, 1, 0, 0]
  [1, 1, 1, 0]
  [0, 0, 1, 0]
]

( (start = r_pentomino, inflation = 8) ->

  board = start.inflate_by(inflation)

  console?.log "#{board.generations} generations:\n\n#{board.result().deflate_by(2)}"

)()