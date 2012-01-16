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

  it 'should return a function', ->

    expect( _.isFunction(m) ).toBeTruthy()


  it 'should perform simple string matching', ->

    expect( m(abc).eh ).toEqual(1)


  it 'should perform a multiple step string matching', ->

    expect( m(abc).ceetwo ).toEqual('two')