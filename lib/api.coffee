# This module is part of [cafeaulife.coffee](http:cafeaulife.html).
#
# ## API Module
#
# The API Module provides convenience methods for interacting with squares from the outside

# ### Baseline Setup

# Cafe au Life uses [Underscore.js][u] extensively:
#
# [u]: http://documentcloud.github.com/underscore/
_ = require('underscore')

# YouAreDaChef provides a nice clean set of semantics for AOP
YouAreDaChef = require('YouAreDaChef').YouAreDaChef

# Play with Node and some browsers
exports ?= window or this

# ### Mix the functionality into `Square`

exports.mixInto = ({Square, Cell}) ->

  # ### Import and export

  # `to_json` and `toString` are simple methods for cells.
  _.extend Cell.prototype,
    to_json: ->
      [@value]
    toString: ->
      '' + @value

  # `to_json` and `toString` are memoized methods for squares
  YouAreDaChef(Square)
    .after 'initialize', ->
      @to_json = _.memoize( ->
        a =
          nw: @nw.to_json()
          ne: @ne.to_json()
          se: @se.to_json()
          sw: @sw.to_json()
        b =
          top: _.map( _.zip(a.nw, a.ne), ([left, right]) ->
            if _.isArray(left)
              left.concat(right)
            else
              [left, right]
          )
          bottom: _.map( _.zip(a.sw, a.se), ([left, right]) ->
            if _.isArray(left)
              left.concat(right)
            else
              [left, right]
          )
        b.top.concat(b.bottom)
      )
      @toString = _.memoize( ->
        (_.map @to_json(), (row) ->
          ([' ', '*'][c] for c in row).join('')
        ).join('\n')
      )

  # ### Padding and cropping squares
  #
  # When displaying squares, it is sometimes convenient to crop them to a certain size or pad them with
  # dead cells to increase their size.

  # A method to answer whether a cell is empty
  _.extend Cell.prototype,
    isEmpty: ->
      @value is 0

  # A memoized method to answer whether a square is empty
  YouAreDaChef(Square)
    .after 'initialize', ->
      @isEmpty = _.memoize( ->
        (@nw is @ne is @se is @sw) and @nw.isEmpty()
      )

  # A method to answer the smallest possible non-empty square centered on a square.
  _.extend Square.prototype,
    trim: ->
      if @nw?.sw?.isEmpty() and @nw.nw.isEmpty() and @nw.ne.isEmpty() and \
         @ne.nw.isEmpty() and @ne.ne.isEmpty() and @ne.se.isEmpty() and \
         @se.ne.isEmpty() and @se.se.isEmpty() and @se.sw.isEmpty() and \
         @sw.se.isEmpty() and @sw.sw.isEmpty() and @sw.nw.isEmpty()
        Square.canonicalize
          nw: @nw.se
          ne: @ne.sw
          se: @se.nw
          sw: @sw.ne
        .trim()
      else
        this

# ---
#
# **(c) 2012 [Reg Braithwaite](http://reginald.braythwayt.com)** ([@raganwald](http://twitter.com/raganwald))
#
# Cafe au Life is freely distributable under the terms of the [MIT license](http://en.wikipedia.org/wiki/MIT_License).
#
# The annotated source code was generated directly from the [original source][source] using [Docco][docco].
#
# [source]: https://github.com/raganwald/cafeaulife/blob/master/lib
# [docco]: http://jashkenas.github.com/docco/