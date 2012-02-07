_ = require('underscore')
require 'UnderscoreMatchersForJasmine'

Life = require('../lib/cafeaulife')

describe 'from_json', ->
  
  beforeEach ->
    Life.Square.set_universe_rules()

  describe 'cells', ->

    it 'should handle ones and zeroes', ->

      expect( Life.Square.find_or_create [[1]] ).toEqual(Life.Cell.Alive)

      expect( Life.Square.find_or_create [[0]] ).toEqual(Life.Cell.Dead)

    it 'should handle size two squares', ->

      expect( Life.Square.find_or_create [[1, 0], [0, 1]] ).toEqual(
        Life.Square.find_or_create
          nw: Life.Cell.Alive
          ne: Life.Cell.Dead
          se: Life.Cell.Alive
          sw: Life.Cell.Dead
      )

    it 'should handle size four squares', ->

      expect( Life.Square.find_or_create [
        [0, 0, 0, 1]
        [0, 0, 1, 0]
        [0, 1, 0, 0]
        [1, 0, 0, 0]
      ] ).toEqual(
        Life.Square.find_or_create
          nw: Life.Square.find_or_create
            nw: Life.Cell.Dead
            ne: Life.Cell.Dead
            se: Life.Cell.Dead
            sw: Life.Cell.Dead
          ne: Life.Square.find_or_create
            nw: Life.Cell.Dead
            ne: Life.Cell.Alive
            se: Life.Cell.Dead
            sw: Life.Cell.Alive
          se: Life.Square.find_or_create
            nw: Life.Cell.Dead
            ne: Life.Cell.Dead
            se: Life.Cell.Dead
            sw: Life.Cell.Dead
          sw: Life.Square.find_or_create
            nw: Life.Cell.Dead
            ne: Life.Cell.Alive
            se: Life.Cell.Dead
            sw: Life.Cell.Alive
      )

      expect( Life.Square.find_or_create [
        [0, 0, 0, 0]
        [0, 0, 1, 0]
        [0, 1, 0, 0]
        [0, 0, 0, 1]
      ] ).toEqual(
        Life.Square.find_or_create
          nw: Life.Square.find_or_create
            nw: Life.Cell.Dead
            ne: Life.Cell.Dead
            se: Life.Cell.Dead
            sw: Life.Cell.Dead
          ne: Life.Square.find_or_create
            nw: Life.Cell.Dead
            ne: Life.Cell.Dead
            se: Life.Cell.Dead
            sw: Life.Cell.Alive
          se: Life.Square.find_or_create
            nw: Life.Cell.Dead
            ne: Life.Cell.Dead
            se: Life.Cell.Alive
            sw: Life.Cell.Dead
          sw: Life.Square.find_or_create
            nw: Life.Cell.Dead
            ne: Life.Cell.Alive
            se: Life.Cell.Dead
            sw: Life.Cell.Dead
      )