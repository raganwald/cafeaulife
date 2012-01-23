_ = require('underscore')
C = require('lib/cafeaulife')
require 'lib/seeds'

r_pentomino = C.Square.find_or_create [
  [0, 1, 1, 0]
  [1, 1, 0, 0]
  [0, 1, 0, 0]
  [0, 0, 0, 0]
]

boat = C.Square.find_or_create [
  [0, 1, 0, 0]
  [1, 0, 1, 0]
  [0, 1, 1, 0]
  [0, 0, 0, 0]
]

( (start = r_pentomino, inflation = 8) ->

  board = start.inflate_by(inflation)

  console?.log '' + board.result().deflate_by(3)

)()