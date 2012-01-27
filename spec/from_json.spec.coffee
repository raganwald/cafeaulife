_ = require('underscore')
require 'UnderscoreMatchersForJasmine'

_.defaults global, require('../lib/cafeaulife')

require( 'lib/lifelike' ).generate_seeds_from_rule [2,3],[3]

describe 'from_json', ->

  describe 'cells', ->

    it 'should handle ones and zeroes', ->

      expect( Square.find_or_create [[1]] ).toEqual(Cell.Alive)

      expect( Square.find_or_create [[0]] ).toEqual(Cell.Dead)

    it 'should handle size two squares', ->

      expect( Square.find_or_create [[1, 0], [0, 1]] ).toEqual(
        Square.find_or_create
          nw: Cell.Alive
          ne: Cell.Dead
          se: Cell.Alive
          sw: Cell.Dead
      )

    it 'should handle size four squares', ->

      expect( Square.find_or_create [
        [0, 0, 0, 1]
        [0, 0, 1, 0]
        [0, 1, 0, 0]
        [1, 0, 0, 0]
      ] ).toEqual(
        Square.find_or_create
          nw: Square.find_or_create
            nw: Cell.Dead
            ne: Cell.Dead
            se: Cell.Dead
            sw: Cell.Dead
          ne: Square.find_or_create
            nw: Cell.Dead
            ne: Cell.Alive
            se: Cell.Dead
            sw: Cell.Alive
          se: Square.find_or_create
            nw: Cell.Dead
            ne: Cell.Dead
            se: Cell.Dead
            sw: Cell.Dead
          sw: Square.find_or_create
            nw: Cell.Dead
            ne: Cell.Alive
            se: Cell.Dead
            sw: Cell.Alive
      )

      expect( Square.find_or_create [
        [0, 0, 0, 0]
        [0, 0, 1, 0]
        [0, 1, 0, 0]
        [0, 0, 0, 1]
      ] ).toEqual(
        Square.find_or_create
          nw: Square.find_or_create
            nw: Cell.Dead
            ne: Cell.Dead
            se: Cell.Dead
            sw: Cell.Dead
          ne: Square.find_or_create
            nw: Cell.Dead
            ne: Cell.Dead
            se: Cell.Dead
            sw: Cell.Alive
          se: Square.find_or_create
            nw: Cell.Dead
            ne: Cell.Dead
            se: Cell.Alive
            sw: Cell.Dead
          sw: Square.find_or_create
            nw: Cell.Dead
            ne: Cell.Alive
            se: Cell.Dead
            sw: Cell.Dead
      )