_ = require('underscore')
require 'UnderscoreMatchersForJasmine'

_.defaults global, require('../lib/cafeaulife.coffee').cafeaulife


describe 'cafe au life', ->

  describe 'to_json', ->

    square_1 = new Divisible
      nw: Alive
      ne: Alive
      se: Dead
      sw: Alive

    it 'should handle a square of 1', ->

      expect( square_1.to_json() ).toEqual [ [1, 1], [1, 0] ]