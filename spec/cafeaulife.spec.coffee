_ = require('underscore')
require 'UnderscoreMatchersForJasmine'

_.defaults global, require('../lib/cafeaulife').cafeaulife

require('../lib/seeds')

describe 'cafe au life', ->

  size_two_empties = Square.find
    nw: Indivisible.Dead
    ne: Indivisible.Dead
    se: Indivisible.Dead
    sw: Indivisible.Dead

  size_two_fulls = Square.find
    nw: Indivisible.Alive
    ne: Indivisible.Alive
    se: Indivisible.Alive
    sw: Indivisible.Alive

  describe 'non-trivial squares', ->

    size_four_empties = Square.find_or_create
      nw: size_two_empties
      ne: size_two_empties
      se: size_two_empties
      sw: size_two_empties

    size_four_fulls = Square.find_or_create
      nw: size_two_fulls
      ne: size_two_fulls
      se: size_two_fulls
      sw: size_two_fulls

    size_eight_empties = Square.find_or_create
      nw: size_four_empties
      ne: size_four_empties
      se: size_four_empties
      sw: size_four_empties

    it 'should compute results', ->

      expect(size_eight_empties.result).toBeTruthy()

    it 'should compute square results', ->

      expect(size_eight_empties.result).toBeA(Square)

    it 'should compute result squares that are full of empty cells', ->

      expect(size_eight_empties.result).toEqual(size_four_empties)


  # describe 'Square.find', ->
  #
  #   # TODO: Find a more complex example, because these will be pre-computed and will exist in the hash
  #   a = new Divisible
  #     nw: size_two_fulls
  #     ne: size_two_empties
  #     se: size_two_fulls
  #     sw: size_two_empties
  #
  #   b = new Divisible
  #     nw: size_two_empties
  #     ne: size_two_fulls
  #     se: size_two_empties
  #     sw: size_two_fulls
  #
  #   it 'should find a in the hash', ->
  #
  #     expect( Square.find
  #       nw: size_two_fulls
  #       ne: size_two_empties
  #       se: size_two_fulls
  #       sw: size_two_empties
  #     ).toEqual(
  #       a
  #     )
  #
  #   it 'should not find something not (yet) in the hash', ->
  #
  #     expect( Square.find
  #       nw: size_two_fulls
  #       ne: size_two_fulls
  #       se: size_two_empties
  #       sw: size_two_empties
  #     ).toBeFalsy()


  describe 'to_json', ->

    square_1 = Square.find
      nw: Indivisible.Alive
      ne: Indivisible.Alive
      se: Indivisible.Dead
      sw: Indivisible.Alive

    it 'should handle a square of 1', ->

      expect( square_1.to_json() ).toEqual [ [1, 1], [1, 0] ]