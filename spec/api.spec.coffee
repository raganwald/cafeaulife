_ = require('underscore')
require 'UnderscoreMatchersForJasmine'

Life = require('../lib/cafeaulife').set_universe_rules()

describe 'from_json', ->

  describe 'squares', ->

    it 'should accept rectangles', ->

      expect( Life.Square.from_json [
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1]
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1]
        [1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
        [1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1, 1, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
        [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
      ]).toBeA(Life.Square)

    it 'should accept strings', ->

      expect( Life.Square.from_string '''
        ....O...
        ..O.O...
        ......O.
        OO......
        ......OO
        .O......
        ...O.O..
        ...O....
      ''' ).toBeA(Life.Square)

  describe 'cells', ->

    it 'should handle ones and zeroes', ->

      expect( Life.Square.from_json [[1]] ).toEqual(Life.Cell.Alive)

      expect( Life.Square.from_json [[0]] ).toEqual(Life.Cell.Dead)

    it 'should handle size two squares', ->

      expect( Life.Square.from_json [[1, 0], [0, 1]] ).toEqual(
        Life.Square.canonicalize
          nw: Life.Cell.Alive
          ne: Life.Cell.Dead
          se: Life.Cell.Alive
          sw: Life.Cell.Dead
      )

    it 'should handle size four squares', ->

      expect( Life.Square.from_json [
        [0, 0, 0, 1]
        [0, 0, 1, 0]
        [0, 1, 0, 0]
        [1, 0, 0, 0]
      ] ).toEqual(
        Life.Square.canonicalize
          nw: Life.Square.canonicalize
            nw: Life.Cell.Dead
            ne: Life.Cell.Dead
            se: Life.Cell.Dead
            sw: Life.Cell.Dead
          ne: Life.Square.canonicalize
            nw: Life.Cell.Dead
            ne: Life.Cell.Alive
            se: Life.Cell.Dead
            sw: Life.Cell.Alive
          se: Life.Square.canonicalize
            nw: Life.Cell.Dead
            ne: Life.Cell.Dead
            se: Life.Cell.Dead
            sw: Life.Cell.Dead
          sw: Life.Square.canonicalize
            nw: Life.Cell.Dead
            ne: Life.Cell.Alive
            se: Life.Cell.Dead
            sw: Life.Cell.Alive
      )

      expect( Life.Square.from_json [
        [0, 0, 0, 0]
        [0, 0, 1, 0]
        [0, 1, 0, 0]
        [0, 0, 0, 1]
      ] ).toEqual(
        Life.Square.canonicalize
          nw: Life.Square.canonicalize
            nw: Life.Cell.Dead
            ne: Life.Cell.Dead
            se: Life.Cell.Dead
            sw: Life.Cell.Dead
          ne: Life.Square.canonicalize
            nw: Life.Cell.Dead
            ne: Life.Cell.Dead
            se: Life.Cell.Dead
            sw: Life.Cell.Alive
          se: Life.Square.canonicalize
            nw: Life.Cell.Dead
            ne: Life.Cell.Dead
            se: Life.Cell.Alive
            sw: Life.Cell.Dead
          sw: Life.Square.canonicalize
            nw: Life.Cell.Dead
            ne: Life.Cell.Alive
            se: Life.Cell.Dead
            sw: Life.Cell.Dead
      )