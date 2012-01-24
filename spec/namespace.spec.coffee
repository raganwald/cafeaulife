require '../lib/seeds'
require 'UnderscoreMatchersForJasmine'

describe 'namespaces', ->

  it 'should not be polluted', ->

    expect( this['Square'] ).toBeUndefined()