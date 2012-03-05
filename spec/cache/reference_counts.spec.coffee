_ = require('underscore')
require 'UnderscoreMatchersForJasmine'

Life = require('../../lib/cafeaulife').set_universe_rules()

describe 'reference counting', ->

  beforeEach ->
    Life.Square.cache.full_gc()
    @orphan = Life.Square.from_json([
      [0, 0, 0, 0, 0, 0, 0, 0]
      [0, 0, 0, 0, 0, 0, 0, 0]
      [0, 0, 0, 0, 0, 0, 0, 0]
      [0, 0, 0, 1, 0, 0, 0, 0]
      [0, 0, 0, 0, 1, 0, 0, 0]
      [0, 0, 0, 0, 0, 0, 0, 0]
      [0, 0, 0, 0, 0, 0, 0, 0]
      [0, 0, 0, 0, 0, 0, 0, 0]
    ])
    @a = Life.Square.from_json([
      [1, 0, 0, 0, 0, 0, 0, 0]
      [0, 0, 0, 0, 0, 0, 0, 0]
      [0, 0, 0, 0, 0, 0, 0, 0]
      [0, 0, 0, 0, 0, 0, 0, 0]
      [0, 0, 0, 0, 0, 0, 0, 0]
      [0, 0, 0, 0, 0, 0, 0, 0]
      [0, 0, 0, 0, 0, 0, 0, 0]
      [0, 0, 0, 0, 0, 0, 0, 0]
    ])
    @b = Life.Square.from_json([
      [0, 0, 0, 0, 0, 0, 0, 1]
      [0, 0, 0, 0, 0, 0, 0, 0]
      [0, 0, 0, 0, 0, 0, 0, 0]
      [0, 0, 0, 0, 0, 0, 0, 0]
      [0, 0, 0, 0, 0, 0, 0, 0]
      [0, 0, 0, 0, 0, 0, 0, 0]
      [0, 0, 0, 0, 0, 0, 0, 0]
      [0, 0, 0, 0, 0, 0, 0, 0]
    ])
    @c = Life.Square.from_json([
      [0, 0, 0, 0, 0, 0, 0, 0]
      [0, 0, 0, 0, 0, 0, 0, 0]
      [0, 0, 0, 0, 0, 0, 0, 0]
      [0, 0, 0, 0, 0, 0, 0, 0]
      [0, 0, 0, 0, 0, 0, 0, 0]
      [0, 0, 0, 0, 0, 0, 0, 0]
      [0, 0, 0, 0, 0, 0, 0, 0]
      [0, 0, 0, 0, 0, 0, 0, 1]
    ])
    @d = Life.Square.from_json([
      [0, 0, 0, 0, 0, 0, 0, 0]
      [0, 0, 0, 0, 0, 0, 0, 0]
      [0, 0, 0, 0, 0, 0, 0, 0]
      [0, 0, 0, 0, 0, 0, 0, 0]
      [0, 0, 0, 0, 0, 0, 0, 0]
      [0, 0, 0, 0, 0, 0, 0, 0]
      [0, 0, 0, 0, 0, 0, 0, 0]
      [1, 0, 0, 0, 0, 0, 0, 0]
    ])
    @parent = Life.Square.canonicalize
      nw: @a
      ne: @b
      se: @c
      sw: @d

  describe 'gc', ->

    beforeEach ->
      @w = Life.Square.from_json([
        [1, 0, 0, 0, 0, 0, 0, 1]
        [0, 0, 0, 0, 0, 0, 0, 0]
        [0, 0, 0, 0, 0, 0, 0, 0]
        [0, 0, 0, 0, 0, 0, 0, 0]
        [0, 0, 0, 0, 0, 0, 0, 0]
        [0, 0, 0, 0, 0, 0, 0, 0]
        [0, 0, 0, 0, 0, 0, 0, 0]
        [1, 0, 0, 0, 0, 0, 0, 0]
      ])
      @x = Life.Square.from_json([
        [1, 0, 0, 0, 0, 0, 0, 0]
        [0, 0, 0, 0, 0, 0, 0, 0]
        [0, 0, 0, 0, 0, 0, 0, 0]
        [0, 0, 0, 0, 0, 0, 0, 0]
        [0, 0, 0, 0, 0, 0, 0, 0]
        [0, 0, 0, 0, 0, 0, 0, 0]
        [0, 0, 0, 0, 0, 0, 0, 0]
        [0, 0, 0, 0, 0, 0, 0, 1]
      ])
      @y = Life.Square.from_json([
        [0, 0, 0, 0, 0, 0, 0, 1]
        [0, 0, 0, 0, 0, 0, 0, 0]
        [0, 0, 0, 0, 0, 0, 0, 0]
        [0, 0, 0, 0, 0, 0, 0, 0]
        [0, 0, 0, 0, 0, 0, 0, 0]
        [0, 0, 0, 0, 0, 0, 0, 0]
        [0, 0, 0, 0, 0, 0, 0, 0]
        [1, 0, 0, 0, 0, 0, 0, 0]
      ])
      @z = Life.Square.from_json([
        [0, 0, 0, 0, 0, 0, 0, 1]
        [0, 0, 0, 0, 0, 0, 0, 0]
        [0, 0, 0, 0, 0, 0, 0, 0]
        [0, 0, 0, 0, 0, 0, 0, 0]
        [0, 0, 0, 0, 0, 0, 0, 0]
        [0, 0, 0, 0, 0, 0, 0, 0]
        [0, 0, 0, 0, 0, 0, 0, 0]
        [1, 0, 0, 0, 0, 0, 0, 1]
      ])
      @wxyz = Life.Square.canonicalize
        nw: @w
        ne: @x
        se: @y
        sw: @z

    it 'should be possible to do a full gc', ->

      expect( @wxyz.has_references() ).toBeFalsy()

      expect( Life.Square.cache.find(@wxyz) ).toBeTruthy()
      expect( Life.Square.cache.find(@w) ).toBeTruthy()
      expect( Life.Square.cache.find(@x) ).toBeTruthy()
      expect( Life.Square.cache.find(@y) ).toBeTruthy()
      expect( Life.Square.cache.find(@z) ).toBeTruthy()

      Life.Square.cache.full_gc()

      expect( Life.Square.cache.find(@wxyz) ).not.toBeTruthy()
      expect( Life.Square.cache.find(@w) ).not.toBeTruthy()
      expect( Life.Square.cache.find(@x) ).not.toBeTruthy()
      expect( Life.Square.cache.find(@y) ).not.toBeTruthy()
      expect( Life.Square.cache.find(@z) ).not.toBeTruthy()

    it 'should pin inputs with sequence', ->

      expect( Life.Square.cache.find(@wxyz) ).toBeTruthy()
      expect( Life.Square.cache.find(@w) ).toBeTruthy()
      expect( Life.Square.cache.find(@x) ).toBeTruthy()
      expect( Life.Square.cache.find(@y) ).toBeTruthy()
      expect( Life.Square.cache.find(@z) ).toBeTruthy()

      Life.Square.cache.sequence(
        ({w, x, y, z}) ->
          Life.Square.cache.full_gc()
          {w, x, y, z}
      )
        w: @w
        x: @x
        y: @y
        z: @z

      expect( Life.Square.cache.find(@wxyz) ).not.toBeTruthy()
      expect( Life.Square.cache.find(@w) ).toBeTruthy()
      expect( Life.Square.cache.find(@x) ).toBeTruthy()
      expect( Life.Square.cache.find(@y) ).toBeTruthy()
      expect( Life.Square.cache.find(@z) ).toBeTruthy()

    it 'children with multiple parents should not get collected', ->

      wwww = Life.Square.canonicalize
        nw: @w
        ne: @w
        se: @w
        sw: @w

      expect( @w.has_one_reference() ).toBeFalsy()
      expect( @w.has_many_references() ).toBeTruthy()

      wwww.incrementReference()

      expect( Life.Square.cache.find(@wxyz) ).toBeTruthy()
      expect( Life.Square.cache.find(wwww) ).toBeTruthy()
      expect( Life.Square.cache.find(@w) ).toBeTruthy()
      expect( Life.Square.cache.find(@x) ).toBeTruthy()
      expect( Life.Square.cache.find(@y) ).toBeTruthy()
      expect( Life.Square.cache.find(@z) ).toBeTruthy()

      Life.Square.cache.full_gc()

      expect( Life.Square.cache.find(@wxyz) ).not.toBeTruthy()
      expect( Life.Square.cache.find(wwww) ).toBeTruthy()
      expect( Life.Square.cache.find(@w) ).toBeTruthy()
      expect( Life.Square.cache.find(@x) ).not.toBeTruthy()
      expect( Life.Square.cache.find(@y) ).not.toBeTruthy()
      expect( Life.Square.cache.find(@z) ).not.toBeTruthy()

      wwww.decrementReference()

      expect( wwww.has_references() ).toBeFalsy()

      Life.Square.cache.full_gc()

      expect( Life.Square.cache.find(wwww) ).not.toBeTruthy()
      expect( Life.Square.cache.find(@w) ).not.toBeTruthy()

  describe 'basic reference counts', ->

    it 'should be consider an orphan square removable', ->

      expect( @orphan.has_references() ).toBeFalsy()

    it 'should consider a parent square removable', ->

      expect( @parent.has_references() ).toBeFalsy()

    it 'should only give a child one reference no matter how many times you canonicalize it', ->

      expect( @a.has_one_reference() ).toBeTruthy()
      {nw, ne, se, sw} = @parent
      Life.Square.canonicalize {nw, ne, se, sw}
      Life.Square.canonicalize {nw, ne, se, sw}
      Life.Square.canonicalize {nw, ne, se, sw}
      pp = Life.Square.canonicalize {nw, ne, se, sw}
      expect(pp).toEqual(@parent) # referencing the same thing
      expect(nw).toEqual(@a)
      expect( @a.has_one_reference() ).toBeTruthy()

    it 'should count results as references', ->

      b = Life.Square.cache.bucketed()

      r = @parent.result()

      expect( @parent.memoized.result ).toEqual(r)

      @parent.incrementReference()

      Life.Square.cache.full_gc()

      expect(r.has_one_reference()).toBeTruthy()

      @parent.decrementReference()

    it 'blowing just the parent away should make the children removable', ->

      expect( @parent.has_references() ).toBeFalsy()

      expect( Life.Square.cache.removeables() ).toInclude(@parent)

      expect( @a.has_references() ).toBeTruthy()

      expect( Life.Square.cache.removeables() ).not.toInclude(@a)

      @parent.remove()

      expect( Life.Square.cache.removeables() ).not.toInclude(@parent)

      expect( @a.has_references() ).toBeFalsy()

      expect( Life.Square.cache.removeables() ).toInclude(@a)

    it 'blowing the parent away recursively should remove the children', ->

      expect( Life.Square.cache.find(@parent) ).toBeTruthy()
      expect( Life.Square.cache.find(@a) ).toBeTruthy()

      expect( @parent.has_references() ).toBeFalsy()

      @parent.removeRecursively()

      expect( Life.Square.cache.find(@parent) ).not.toBeTruthy()
      expect( Life.Square.cache.find(@a) ).not.toBeTruthy()