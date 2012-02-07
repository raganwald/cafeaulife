_ = require('underscore')
require 'UnderscoreMatchersForJasmine'

Life = require('../lib/cafeaulife')

describe 'time and space', ->

  beforeEach ->
    Life.Square.set_universe_rules()

  describe 'time', ->

    beforeEach ->
      @still_life = Life.Square.canonicalize [
        [1, 1]
        [1, 1]
      ]

      @r_pentomino = Life.Square.canonicalize [
        [0, 0, 0, 0]
        [0, 1, 0, 0]
        [1, 1, 1, 0]
        [0, 0, 1, 0]
      ]

    it 'should move a block one step into the future', ->

      expect( @still_life.future() ).toEqual( Life.Square.canonicalize [
        [0, 0, 0, 0]
        [0, 1, 1, 0]
        [0, 1, 1, 0]
        [0, 0, 0, 0]
      ] )

    it 'should move an r-pentomino two steps into the future', ->

      expect( @r_pentomino.future() ).toEqual( Life.Square.canonicalize [
        [ 0, 0, 0, 0, 0, 0, 0, 0 ]
        [ 0, 0, 0, 0, 0, 0, 0, 0 ]
        [ 0, 0, 0, 1, 0, 0, 0, 0 ]
        [ 0, 0, 1, 0, 1, 0, 0, 0 ]
        [ 0, 0, 1, 0, 1, 1, 0, 0 ]
        [ 0, 0, 0, 1, 0, 0, 0, 0 ]
        [ 0, 0, 0, 0, 0, 0, 0, 0 ]
        [ 0, 0, 0, 0, 0, 0, 0, 0 ]
      ] )


  describe 'space', ->

    it 'should not change an r_pentomino from level 2', ->

      expect( (Life.Square.canonicalize [
        [0, 0, 0, 0]
        [0, 1, 0, 0]
        [1, 1, 1, 0]
        [0, 0, 1, 0]
      ]).resize_to(2) ).toEqual( Life.Square.canonicalize [
        [0, 0, 0, 0]
        [0, 1, 0, 0]
        [1, 1, 1, 0]
        [0, 0, 1, 0]
      ] )

    it 'should downsize an r_pentomino to level 1', ->

      expect( (Life.Square.canonicalize [
        [0, 0, 0, 0]
        [0, 1, 0, 0]
        [1, 1, 1, 0]
        [0, 0, 1, 0]
      ]).resize_to(1) ).toEqual( Life.Square.canonicalize [
        [1, 0]
        [1, 1]
      ] )

    it 'should upsize a 2x2 to level 3', ->

      expect( (Life.Square.canonicalize [
        [1, 0]
        [0, 1]
      ]).resize_to(3) ).toEqual( Life.Square.canonicalize [
        [0, 0, 0, 0, 0, 0, 0, 0]
        [0, 0, 0, 0, 0, 0, 0, 0]
        [0, 0, 0, 0, 0, 0, 0, 0]
        [0, 0, 0, 1, 0, 0, 0, 0]
        [0, 0, 0, 0, 1, 0, 0, 0]
        [0, 0, 0, 0, 0, 0, 0, 0]
        [0, 0, 0, 0, 0, 0, 0, 0]
        [0, 0, 0, 0, 0, 0, 0, 0]
      ] )

    it 'should trim a 2x2 back to its original size', ->

      expect( (Life.Square.canonicalize [
        [1, 0]
        [0, 1]
      ]).resize_to(3).trim() ).toEqual(Life.Square.canonicalize [
        [1, 0]
        [0, 1]
      ] )