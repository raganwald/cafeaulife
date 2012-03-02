_ = require('underscore')
require 'UnderscoreMatchersForJasmine'

Life = require('../../lib/cafeaulife').set_universe_rules()

describe 'Square.RecursivelyComputable', ->

  beforeEach ->
    i = 0
    @number_map ||=
      nw:
        nw: (i += 1)
        ne: (i += 1)
        se: (i += 1)
        sw: (i += 1)
      ne:
        nw: (i += 1)
        ne: (i += 1)
        se: (i += 1)
        sw: (i += 1)
      se:
        nw: (i += 1)
        ne: (i += 1)
        se: (i += 1)
        sw: (i += 1)
      sw:
        nw: (i += 1)
        ne: (i += 1)
        se: (i += 1)
        sw: (i += 1)

  describe 'map_fn', ->

    it 'should map the identity function', ->

      identity = Life.Square.RecursivelyComputable.map_fn( (x) -> x )

      expect( identity(@number_map.sw).nw ).toEqual( @number_map.sw.nw )

    it 'should map the double function', ->

      double = Life.Square.RecursivelyComputable.map_fn( (x) -> x * 2 )

      expect( double(@number_map.sw).nw ).toEqual( @number_map.sw.nw * 2)

  describe 'canonicalize', ->

    beforeEach ->
      one = Life.Square.from_json [
        [0, 0]
        [1, 0]
      ]
      two = Life.Square.from_json [
        [0, 0]
        [0, 1]
      ]

      @map_of_squares ||=
        foo:
          nw: one
          ne: two
          se: one
          sw: two
        bar:
          nw: two
          ne: two
          se: one
          sw: one

    it 'should canonicalize both elements', ->
      expect(
        Life.Square.RecursivelyComputable.canonicalize(@map_of_squares).foo
      ).toEqual(
        Life.Square.canonicalize(@map_of_squares.foo)
      )
      expect(
        Life.Square.RecursivelyComputable.canonicalize(@map_of_squares).bar
      ).toEqual(
        Life.Square.canonicalize(@map_of_squares.bar)
      )

  describe 'square_to_intermediate_map', ->

    it 'should map as we expect', ->

      expect( @number_map.se.ne ).toEqual(10)

      expect( Life.Square.RecursivelyComputable.square_to_intermediate_map(@number_map).ee.se ).toEqual(@number_map.se.ne)

    it 'should map through an atomic sequence', ->

      expect(
        Life.Square.RecursivelyComputable.sequence(
          Life.Square.RecursivelyComputable.square_to_intermediate_map
        )(@number_map).ee.se
      ).toEqual(@number_map.se.ne)