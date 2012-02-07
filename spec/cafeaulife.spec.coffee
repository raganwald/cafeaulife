_ = require('underscore')
require 'UnderscoreMatchersForJasmine'

# YouAreDaChef provides a nice clean set of semantics for AOP
YouAreDaChef = require('YouAreDaChef').YouAreDaChef

Life = require('../lib/cafeaulife')
Life.Square.set_universe_rules()

# An id for debugging purposes
debug_id = 0
YouAreDaChef(Life.Square)
  .after 'initialize', ->
    @debug_id = (debug_id += 1)

describe 'cafe au life', ->

  beforeEach ->
    Life.Square.set_universe_rules()

  describe '.empty', ->

    beforeEach ->
      @foursq = Life.Square.canonicalize([
        [0, 0, 0, 0]
        [0, 1, 0, 0]
        [0, 0, 1, 0]
        [0, 0, 0, 0]
      ]).empty_copy()

    it 'should be a resulting square', ->

      expect(@foursq).toRespondTo('result')

    it 'should be a resulting square after inflation', ->

      expect(@foursq.pad_by(1)).toRespondTo('result')


  describe '_.memoize', ->

    it 'gratuitously re-result the same thing many times', ->

      sq = Life.Square.canonicalize([[1, 0], [0, 1]])
        .pad_by(2)
      sq.result()

      number_bucketed = Life.Square.cache.bucketed()

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

      expect( Life.Square.cache.bucketed() ).toEqual(number_bucketed)

  describe 'squares', ->

    beforeEach ->

      @size_two_empties = Life.Square.cache.find
        nw: Life.Cell.Dead
        ne: Life.Cell.Dead
        se: Life.Cell.Dead
        sw: Life.Cell.Dead

      @size_two_fulls = Life.Square.cache.find
        nw: Life.Cell.Alive
        ne: Life.Cell.Alive
        se: Life.Cell.Alive
        sw: Life.Cell.Alive

    it 'should support the basics', ->

      expect(Life.Cell.Dead).not.toBeUndefined()

      expect(Life.Cell.Alive).not.toBeUndefined()

    describe 'non-trivial squares', ->

      beforeEach ->
        @size_four_empties = Life.Square.canonicalize
          nw: @size_two_empties
          ne: @size_two_empties
          se: @size_two_empties
          sw: @size_two_empties

        @size_four_fulls = Life.Square.canonicalize
          nw: @size_two_fulls
          ne: @size_two_fulls
          se: @size_two_fulls
          sw: @size_two_fulls

        @size_eight_empties = Life.Square.canonicalize
          nw: @size_four_empties
          ne: @size_four_empties
          se: @size_four_empties
          sw: @size_four_empties

      it 'should compute results', ->

        expect(@size_eight_empties.result()).toBeTruthy()

      it 'should compute square results', ->

        expect(@size_eight_empties.result()).toBeA(Life.Square)

      it 'should compute result squares that are full of empty cells', ->

        expect(@size_eight_empties.result()).toEqual(@size_four_empties)


    describe 'inflation', ->

      beforeEach ->
        @two_by_two = Life.Square.canonicalize [
          [1, 0]
          [0, 1]
        ]

      it 'should not inflate cells', ->

        expect(Life.Cell.Alive).not.toRespondTo('pad_by')

      it 'should inflate 2x2 at zero level to itself', ->

        expect(@two_by_two.pad_by(0)).toEqual(Life.Square.canonicalize [
          [1, 0]
          [0, 1]
        ])

      it 'should inflate 2x2 at one level to double itself', ->

        expect(@two_by_two.pad_by(1).to_json()).toEqual([
          [0, 0, 0, 0]
          [0, 1, 0, 0]
          [0, 0, 1, 0]
          [0, 0, 0, 0]
        ])

      it 'should inflate 2x2 at two levels to quadruple itself', ->

        expect(@two_by_two.pad_by(2).to_json()).toEqual([
          [0, 0, 0, 0, 0, 0, 0, 0]
          [0, 0, 0, 0, 0, 0, 0, 0]
          [0, 0, 0, 0, 0, 0, 0, 0]
          [0, 0, 0, 1, 0, 0, 0, 0]
          [0, 0, 0, 0, 1, 0, 0, 0]
          [0, 0, 0, 0, 0, 0, 0, 0]
          [0, 0, 0, 0, 0, 0, 0, 0]
          [0, 0, 0, 0, 0, 0, 0, 0]
        ])

    describe 'deflation', ->

      beforeEach ->
        @square = Life.Square.canonicalize [
          [0, 0, 0, 0, 0, 0, 0, 1]
          [0, 1, 0, 0, 0, 0, 0, 0]
          [0, 0, 0, 0, 0, 1, 0, 0]
          [0, 0, 0, 1, 0, 0, 0, 0]
          [1, 1, 1, 0, 1, 1, 0, 0]
          [1, 0, 0, 1, 0, 1, 0, 0]
          [1, 0, 0, 1, 0, 1, 1, 1]
          [0, 1, 1, 1, 0, 0, 0, 1]
        ]

      it 'should have a zero deflation', ->

        expect( @square.crop_by(0) ).toEqual(
          Life.Square.canonicalize [
            [0, 0, 0, 0, 0, 0, 0, 1]
            [0, 1, 0, 0, 0, 0, 0, 0]
            [0, 0, 0, 0, 0, 1, 0, 0]
            [0, 0, 0, 1, 0, 0, 0, 0]
            [1, 1, 1, 0, 1, 1, 0, 0]
            [1, 0, 0, 1, 0, 1, 0, 0]
            [1, 0, 0, 1, 0, 1, 1, 1]
            [0, 1, 1, 1, 0, 0, 0, 1]
          ]
        )

      it 'should deflate by one', ->

        expect( @square.crop_by(1) ).toEqual(
          Life.Square.canonicalize [
            [0, 0, 0, 1]
            [0, 1, 0, 0]
            [1, 0, 1, 1]
            [0, 1, 0, 1]
          ]
        )

      it 'should deflate by two', ->

        expect( @square.crop_by(2) ).toEqual(
          Life.Square.canonicalize [
            [1, 0]
            [0, 1]
          ]
        )

    describe 'progress', ->

      it 'should persist a block', ->

        still_life = Life.Square.canonicalize [
          [1, 1]
          [1, 1]
        ]

        inflated = still_life.pad_by(3)

        expect(inflated.result().to_json()).toEqual(still_life.pad_by(2).to_json())

        expect(inflated.result()).toEqual(still_life.pad_by(2))

      it 'should kill orphans', ->

        orphans = Life.Square.canonicalize [
          [0, 0]
          [1, 1]
        ]

        inflated = orphans.pad_by(3)

        expect(inflated.result().to_json()).not.toEqual(orphans.pad_by(2).to_json())

        expect(inflated.result().to_json()).toEqual(orphans.pad_by(2).empty_copy().to_json())

      it 'should birth a square with three neighbours', ->

        parents = Life.Square.canonicalize [
          [0, 1]
          [1, 1]
        ]

        block = Life.Square.canonicalize [
          [1, 1]
          [1, 1]
        ]

        inflated = parents.pad_by(1)

        expect( inflated.result() ).toEqual(block)

    describe 'still life forms should persist', ->

      beforeEach ->
        @blocks = [
          Life.Square.canonicalize [
            [1, 1]
            [1, 1]
          ]
        ]

        @boats = [
          Life.Square.canonicalize [
            [0, 1, 0, 0]
            [1, 0, 1, 0]
            [0, 1, 1, 0]
            [0, 0, 0, 0]
          ]
          Life.Square.canonicalize [
            [0, 0, 1, 0]
            [0, 1, 0, 1]
            [0, 1, 1, 0]
            [0, 0, 0, 0]
          ]
          Life.Square.canonicalize [
            [0, 0, 0, 0]
            [0, 1, 1, 0]
            [0, 1, 0, 1]
            [0, 0, 1, 0]
          ]
          Life.Square.canonicalize [
            [0, 0, 0, 0]
            [0, 1, 1, 0]
            [1, 0, 1, 0]
            [0, 1, 0, 0]
          ]
        ]

      it 'should find identical blocks by number', ->
        expect(Life.Square.canonicalize [
          [1, 1]
          [1, 1]
        ]).toEqual(Life.Square.canonicalize [
          [1, 1]
          [1, 1]
        ])

      it 'should have a block in the cache', ->
        expect(Life.Square.cache.find
          nw: Life.Cell.Alive
          ne: Life.Cell.Alive
          se: Life.Cell.Alive
          sw: Life.Cell.Alive
        ).not.toBeUndefined()

      it 'should come up with identical blocks', ->
        expect(Life.Square.cache.find
          nw: Life.Cell.Alive
          ne: Life.Cell.Alive
          se: Life.Cell.Alive
          sw: Life.Cell.Alive
        ).toEqual(Life.Square.canonicalize [
          [1, 1]
          [1, 1]
        ])

      _.each {
        Block: @blocks
        Boat: @boats
      }, (examples, name) ->
        _.each examples, (square) ->
          it "Should not change a #{name}", ->
            console?.log square.debug_id, square.pad_by(1).result().debug_id
            expect( square.pad_by(1).result() ).toEqual(square)

    describe 'to_json', ->

      beforeEach ->
        @square_1 = Life.Square.cache.find
          nw: Life.Cell.Alive
          ne: Life.Cell.Alive
          se: Life.Cell.Dead
          sw: Life.Cell.Alive

      it 'should handle a square of 1', ->

        expect( @square_1.to_json() ).toEqual [ [1, 1], [1, 0] ]