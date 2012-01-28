C = require('../../lib/cafeaulife')
require( '../../lib/lifelike' ).generate_seeds_from_rule [1..5],[3]

wickstretcher = C.Square.find_or_create [
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

  board = start.inflate_by(inflation)

  console?.log "#{board.generations} generations:\n\n#{board.result().deflate_by(1)}"

)()