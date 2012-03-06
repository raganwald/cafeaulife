_ = require('underscore')
require 'UnderscoreMatchersForJasmine'

Life = require('../lib/cafeaulife').set_universe_rules()
{acorn, block, r} = require('../lib/menagerie')

describe 'time and space', ->

    it 'should move a block one step into the future', ->

      expect( block.future_at_time(1).trim() ).toEqual(
        Life.Square.from_json [
          [1, 1]
          [1, 1]
        ]
      )

    it 'should move an r-pentomino two steps into the future', ->

      expect( r.future_at_time(2).trim() ).toEqual( Life.Square.from_json [
        [0, 1, 0, 0]
        [1, 0, 1, 0]
        [1, 0, 1, 1]
        [0, 1, 0, 0]
      ] )

    it 'should generate a population of 116 from an r pentomino', ->

      future = r.future_at_time(1103)

      expect( future.population ).toEqual( 116 )

      expect( future.level ).toEqual( 12 )

    it 'should generate a population of 633 from an acorn', ->

      expect( acorn.future_at_time(5206).population ).toEqual( 633 )


  describe 'space', ->

    # it 'should not change an r_pentomino from level 2', ->
    #
    #   expect( (Life.Square.from_json [
    #     [0, 0, 0, 0]
    #     [0, 1, 0, 0]
    #     [1, 1, 1, 0]
    #     [0, 0, 1, 0]
    #   ]).resize_to(2) ).toEqual( Life.Square.from_json [
    #     [0, 0, 0, 0]
    #     [0, 1, 0, 0]
    #     [1, 1, 1, 0]
    #     [0, 0, 1, 0]
    #   ] )
    #
    # it 'should downsize an r_pentomino to level 1', ->
    #
    #   expect( (Life.Square.from_json [
    #     [0, 0, 0, 0]
    #     [0, 1, 0, 0]
    #     [1, 1, 1, 0]
    #     [0, 0, 1, 0]
    #   ]).resize_to(1) ).toEqual( Life.Square.from_json [
    #     [1, 0]
    #     [1, 1]
    #   ] )
    #
    # it 'should upsize a 2x2 to level 3', ->
    #
    #   expect( (Life.Square.from_json [
    #     [1, 0]
    #     [0, 1]
    #   ]).resize_to(3) ).toEqual( Life.Square.from_json [
    #     [0, 0, 0, 0, 0, 0, 0, 0]
    #     [0, 0, 0, 0, 0, 0, 0, 0]
    #     [0, 0, 0, 0, 0, 0, 0, 0]
    #     [0, 0, 0, 1, 0, 0, 0, 0]
    #     [0, 0, 0, 0, 1, 0, 0, 0]
    #     [0, 0, 0, 0, 0, 0, 0, 0]
    #     [0, 0, 0, 0, 0, 0, 0, 0]
    #     [0, 0, 0, 0, 0, 0, 0, 0]
    #   ] )

    it 'should trim an 8x8 down to 4x4', ->
      expect( Life.Square.from_json([
        [ 0, 0, 0, 0, 0, 0, 0, 0 ],
        [ 0, 0, 0, 0, 0, 0, 0, 0 ],
        [ 0, 0, 0, 1, 0, 0, 0, 0 ],
        [ 0, 0, 1, 0, 1, 0, 0, 0 ],
        [ 0, 0, 1, 0, 1, 1, 0, 0 ],
        [ 0, 0, 0, 1, 0, 0, 0, 0 ],
        [ 0, 0, 0, 0, 0, 0, 0, 0 ],
        [ 0, 0, 0, 0, 0, 0, 0, 0 ] ]).trim()
      ).toEqual( Life.Square.from_json [
        [0, 1, 0, 0]
        [1, 0, 1, 0]
        [1, 0, 1, 1]
        [0, 1, 0, 0]
      ] )

    it 'should trim a 2x2 back to its original size', ->

      expect( (Life.Square.from_json [
        [0, 0, 0, 0, 0, 0, 0, 0]
        [0, 0, 0, 0, 0, 0, 0, 0]
        [0, 0, 0, 0, 0, 0, 0, 0]
        [0, 0, 0, 1, 0, 0, 0, 0]
        [0, 0, 0, 0, 1, 0, 0, 0]
        [0, 0, 0, 0, 0, 0, 0, 0]
        [0, 0, 0, 0, 0, 0, 0, 0]
        [0, 0, 0, 0, 0, 0, 0, 0]
      ]).trim() ).toEqual(Life.Square.from_json [
        [1, 0]
        [0, 1]
      ] )