global = this

mapper = require('../lib/mapping.coffee').mapper
_ = require('underscore')
require 'UnderscoreMatchersForJasmine'

describe 'basic mapper', ->

  abc =
    a: 1
    b: 2
    c:
      c1: 'one'
      c2: 'two'
      c3: 'three'

  m = mapper
    eh: 'a'
    ceetwo: 'c.c2'
    ceemap:
      one: 'c.c1',
      two: 'c.c2'
    fn: (obj) -> obj.a + obj.b
    simplecomp: [
      (x) -> x + 2
      (x) -> x.a
    ]
    timestwoplusone: [
      (x) -> x + 1
      (x) -> x * 2
      'b'
    ]

  it 'should return a function', ->

    expect( _.isFunction(m) ).toBeTruthy()


  it 'should perform simple string matching', ->

    expect( m(abc).eh ).toEqual 1


  it 'should perform multiple step string matching', ->

    expect( m(abc).ceetwo ).toEqual 'two'

  it 'should perform simple hash mapping', ->

    expect( m(abc).ceemap ).toEqual
      one: 'one'
      two: 'two'

  it 'should handle custom functions', ->
    expect( m(abc).fn ).toEqual 3

  it 'should compose multiple simple functions', ->
    expect( m(abc).timestwoplusone ).toEqual 5
