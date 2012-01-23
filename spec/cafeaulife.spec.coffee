_ = require('underscore')
require 'UnderscoreMatchersForJasmine'

_.defaults global, require('../lib/cafeaulife')

require('../lib/seeds')

describe '.empty', ->

  foursq = Square.find_or_create([
    [0, 0, 0, 0]
    [0, 1, 0, 0]
    [0, 0, 1, 0]
    [0, 0, 0, 0]
  ]).empty_copy()

  it 'should be a resulting square', ->

    expect(foursq).toRespondTo('result')

  it 'should be a resulting square after inflation', ->

    expect(foursq.inflate_by(1)).toRespondTo('result')


describe '_.memoize', ->

  it 'gratuitously re-result the same thing many times', ->

    sq = Square.find_or_create([[1, 0], [0, 1]])
      .inflate_by(2)
    sq.result()

    number_bucketed = Square.bucketed()

    sq.result()
    sq.result()
    sq.result()
    sq.result()
    sq.result()
    sq.result()
    sq.result()
    sq.result()
    sq.result()
    sq.result()

    expect( Square.bucketed() ).toEqual(number_bucketed)

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

  it 'should support the basics', ->

    expect(Indivisible.Dead).not.toBeUndefined()

    expect(Indivisible.Alive).not.toBeUndefined()

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

      expect(size_eight_empties.result()).toBeTruthy()

    it 'should compute square results', ->

      expect(size_eight_empties.result()).toBeA(Square)

    it 'should compute result squares that are full of empty cells', ->

      expect(size_eight_empties.result()).toEqual(size_four_empties)


  describe 'inflation', ->

    two_by_two = Square.find_or_create [[1, 0], [0, 1]]

    it 'should not inflate cells', ->

      expect(Indivisible.Alive).not.toRespondTo('inflate_by')

    it 'should inflate 2x2 at zero level to itself', ->

      expect(two_by_two.inflate_by(0)).toEqual(Square.find_or_create [
        [1, 0]
        [0, 1]
      ])

    it 'should inflate 2x2 at one level to double itself', ->

      expect(two_by_two.inflate_by(1).to_json()).toEqual([
        [0, 0, 0, 0]
        [0, 1, 0, 0]
        [0, 0, 1, 0]
        [0, 0, 0, 0]
      ])

    it 'should inflate 2x2 at two levels to quadruple itself', ->

      expect(two_by_two.inflate_by(2).to_json()).toEqual([
        [0, 0, 0, 0, 0, 0, 0, 0]
        [0, 0, 0, 0, 0, 0, 0, 0]
        [0, 0, 0, 0, 0, 0, 0, 0]
        [0, 0, 0, 1, 0, 0, 0, 0]
        [0, 0, 0, 0, 1, 0, 0, 0]
        [0, 0, 0, 0, 0, 0, 0, 0]
        [0, 0, 0, 0, 0, 0, 0, 0]
        [0, 0, 0, 0, 0, 0, 0, 0]
      ])

  describe 'progress', ->

    it 'should persist a block', ->

      still_life = Square.find_or_create [
        [1, 1]
        [1, 1]
      ]

      inflated = still_life.inflate_by(3)

      expect(inflated.result().to_json()).toEqual(still_life.inflate_by(2).to_json())

      expect(inflated.result()).toEqual(still_life.inflate_by(2))

    it 'should kill orphans', ->

      orphans = Square.find_or_create [
        [0, 0]
        [1, 1]
      ]

      inflated = orphans.inflate_by(3)

      expect(inflated.result().to_json()).not.toEqual(orphans.inflate_by(2).to_json())

      expect(inflated.result().to_json()).toEqual(orphans.inflate_by(2).empty_copy().to_json())

    it 'should birth a square with three neighbours', ->

      parents = Square.find_or_create [
        [0, 1]
        [1, 1]
      ]

      block = Square.find_or_create [
        [1, 1]
        [1, 1]
      ]

      inflated = parents.inflate_by(1)

      expect( inflated.result() ).toEqual(block)

  describe 'still life forms should persist', ->

    blocks = [
      Square.find_or_create [
        [1, 1]
        [1, 1]
      ]
    ]

    boats = [
      Square.find_or_create [
        [0, 1, 0, 0]
        [1, 0, 1, 0]
        [0, 1, 1, 0]
        [0, 0, 0, 0]
      ]
      Square.find_or_create [
        [0, 0, 1, 0]
        [0, 1, 0, 1]
        [0, 1, 1, 0]
        [0, 0, 0, 0]
      ]
      Square.find_or_create [
        [0, 0, 0, 0]
        [0, 1, 1, 0]
        [0, 1, 0, 1]
        [0, 0, 1, 0]
      ]
      Square.find_or_create [
        [0, 0, 0, 0]
        [0, 1, 1, 0]
        [1, 0, 1, 0]
        [0, 1, 0, 0]
      ]
    ]

    _.each {Block: blocks, Boat: boats}, (examples, name) ->
      _.each examples, (square) ->
        it "Should not change a #{name}", ->
          expect( square.inflate_by(1).result() ).toEqual(square)

  describe 'to_json', ->

    square_1 = Square.find
      nw: Indivisible.Alive
      ne: Indivisible.Alive
      se: Indivisible.Dead
      sw: Indivisible.Alive

    it 'should handle a square of 1', ->

      expect( square_1.to_json() ).toEqual [ [1, 1], [1, 0] ]