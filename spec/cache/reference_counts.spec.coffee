_ = require('underscore')
require 'UnderscoreMatchersForJasmine'

Life = require('../../lib/cafeaulife').set_universe_rules()

describe 'reference counts', ->

  beforeEach ->
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

    r = @parent.result()
    r = @parent.result()
    r = @parent.result()
    r = @parent.result()
    r = @parent.result()

    expect(r).not.toEqual(@a)
    expect(r).not.toEqual(@b)
    expect(r).not.toEqual(@c)
    expect(r).not.toEqual(@d)

    expect(r.has_one_reference()).toBeTruthy()