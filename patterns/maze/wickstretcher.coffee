Life = require('../../lib/cafeaulife')
Life.set_universe_rules [1..5],[3]

wickstretcher = Life.Square.from_json [
  [0, 1, 1, 0, 0, 0, 0, 0]
  [0, 0, 1, 1, 1, 0, 0, 0]
  [0, 0, 1, 0, 1, 1, 0, 0]
  [0, 0, 0, 0, 1, 1, 1, 0]
  [0, 0, 0, 0, 1, 1, 0, 0]
  [0, 0, 1, 0, 1, 0, 0, 0]
  [0, 0, 1, 1, 1, 0, 0, 0]
  [0, 1, 1, 0, 0, 0, 0, 0]
]

( (start = wickstretcher, inflation = 6) ->

  board = start.pad_by(inflation)

  console?.log "#{board.generations} generations:\n\n#{board.result().crop_by(1)}"

)()