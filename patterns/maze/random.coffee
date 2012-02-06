Life = require('../../lib/cafeaulife')
Life.set_universe_rules [1..5],[3]

random = Life.Square.find_or_create [
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

  board = start.pad_by(inflation)

  console?.log "#{board.generations} generations:\n\n#{board.result().crop_by(1)}"

)()