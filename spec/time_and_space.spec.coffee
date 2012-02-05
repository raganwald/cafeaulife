_ = require('underscore')
require 'UnderscoreMatchersForJasmine'

Life = require('../lib/cafeaulife')

describe 'time and space', ->

  beforeEach ->
    Life.generate_seeds_from_rule()

  describe 'time', ->

    beforeEach ->
      @still_life = Life.Square.find_or_create [
        [1, 1]
        [1, 1]
      ]

    # This test is wrong on the level of a square. It ight work for a game board, but it definitely
    # doesn't work for a square.
    it 'should move this one step into the future' #, ->

      # expect( @still_life.future(1) ).toEqual( Life.Square.find_or_create [
      #   [0, 0, 0, 0]
      #   [0, 1, 1, 0]
      #   [0, 1, 1, 0]
      #   [0, 0, 0, 0]
      # ])

  describe 'space', ->

    it 'should not change an r_pentomino from level 2', ->

      expect( (Life.Square.find_or_create [
        [0, 0, 0, 0]
        [0, 1, 0, 0]
        [1, 1, 1, 0]
        [0, 0, 1, 0]
      ]).resize_to(2) ).toEqual( Life.Square.find_or_create [
        [0, 0, 0, 0]
        [0, 1, 0, 0]
        [1, 1, 1, 0]
        [0, 0, 1, 0]
      ] )

    it 'should downsize an r_pentomino to level 1', ->

      expect( (Life.Square.find_or_create [
        [0, 0, 0, 0]
        [0, 1, 0, 0]
        [1, 1, 1, 0]
        [0, 0, 1, 0]
      ]).resize_to(1) ).toEqual( Life.Square.find_or_create [
        [1, 0]
        [1, 1]
      ] )

    it 'should upsize an r_pentomino to level 3', ->

      expect( (Life.Square.find_or_create [
        [1, 0]
        [0, 1]
      ]).resize_to(3) ).toEqual( Life.Square.find_or_create [
        [0, 0, 0, 0, 0, 0, 0, 0]
        [0, 0, 0, 0, 0, 0, 0, 0]
        [0, 0, 0, 0, 0, 0, 0, 0]
        [0, 0, 0, 1, 0, 0, 0, 0]
        [0, 0, 0, 0, 1, 0, 0, 0]
        [0, 0, 0, 0, 0, 0, 0, 0]
        [0, 0, 0, 0, 0, 0, 0, 0]
        [0, 0, 0, 0, 0, 0, 0, 0]
      ] )