_ = require('underscore')
require 'UnderscoreMatchersForJasmine'

_.defaults global, require('../lib/cafeaulife').cafeaulife

require('../lib/seeds')

describe 'from_json', ->

  describe 'cells', ->

    it 'should handle ones and zeroes', ->

      expect( Square.find_or_create [[1]] ).toEqual(Indivisible.Alive)

      expect( Square.find_or_create [[0]] ).toEqual(Indivisible.Dead)

    it 'should handle size two squares', ->

      expect( Square.find_or_create [[1, 0], [0, 1]] ).toEqual(
        Square.find_or_create
          nw: Indivisible.Alive
          ne: Indivisible.Dead
          se: Indivisible.Alive
          sw: Indivisible.Dead
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
            nw: Indivisible.Dead
            ne: Indivisible.Dead
            se: Indivisible.Dead
            sw: Indivisible.Dead
          ne: Square.find_or_create
            nw: Indivisible.Dead
            ne: Indivisible.Alive
            se: Indivisible.Dead
            sw: Indivisible.Alive
          se: Square.find_or_create
            nw: Indivisible.Dead
            ne: Indivisible.Dead
            se: Indivisible.Dead
            sw: Indivisible.Dead
          sw: Square.find_or_create
            nw: Indivisible.Dead
            ne: Indivisible.Alive
            se: Indivisible.Dead
            sw: Indivisible.Alive
      )

      expect( Square.find_or_create [
        [0, 0, 0, 0]
        [0, 0, 1, 0]
        [0, 1, 0, 0]
        [0, 0, 0, 1]
      ] ).toEqual(
        Square.find_or_create
          nw: Square.find_or_create
            nw: Indivisible.Dead
            ne: Indivisible.Dead
            se: Indivisible.Dead
            sw: Indivisible.Dead
          ne: Square.find_or_create
            nw: Indivisible.Dead
            ne: Indivisible.Dead
            se: Indivisible.Dead
            sw: Indivisible.Alive
          se: Square.find_or_create
            nw: Indivisible.Dead
            ne: Indivisible.Dead
            se: Indivisible.Alive
            sw: Indivisible.Dead
          sw: Square.find_or_create
            nw: Indivisible.Dead
            ne: Indivisible.Alive
            se: Indivisible.Dead
            sw: Indivisible.Dead
      )