C = require('../../lib/cafeaulife')
C.set_universe_rules [1..5],[3]

random = C.Square.find_or_create [
  Math.floor(Math.random()*2) for x in [1..8]
  Math.floor(Math.random()*2) for x in [1..8]
  Math.floor(Math.random()*2) for x in [1..8]
  Math.floor(Math.random()*2) for x in [1..8]
  Math.floor(Math.random()*2) for x in [1..8]
  Math.floor(Math.random()*2) for x in [1..8]
  Math.floor(Math.random()*2) for x in [1..8]
  Math.floor(Math.random()*2) for x in [1..8]
]

( (start = random, inflation = 6) ->

  board = start.inflate_by(inflation)

  console?.log "#{board.generations} generations:\n\n#{board.result().deflate_by(1)}"

)()