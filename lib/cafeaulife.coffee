# # Cafe au Life

## What

# Cafe au Life is an implementation of John Conway's [Game of Life][life] cellular automata
# written in [CoffeeScript][cs]. Cafe au Life runs on [Node.js][node], it is not designed
# to run as an interactive program in a browser window.
#
# Cafe au Life's Github project is [here](https://github.com/raganwald/cafeaulife/).
#
# This file, [cafeaulife.coffee][source] contains the core engine for computing the future of any life universe
# of size `2^n | n > 1`. The algorithm is optimized for computing very large numbers of generations
#  of very large and complex life patterns with a high degree of regularity such as implementing
# Turing machines.
#
# As such, it is particularly poorly suited for animating displays a generation at a time. But it
# is still a beautiful algorithm that touches on the soul of life’s “physics."
#
# ![Period 24 Glider Gun](http:Trueperiod24gun.png)
#
# *(A period 24 Glider Gun. Gliders of different periods are useful for synchronizing signals in complex
# Life machines.)*
#
# ### Conway's Life and other two-dimensional cellular automata
#
# The Life Universe is an infinite two-dimensional matrix of cells. Cells are indivisible and are in either of two states,
# commonly called "alive" and "dead." Time is represented as discrete quanta called either "ticks" or "generations."
# With each generation, a rule is applied to decide the state the cell will assume. The rules are decided simultaneously,
# and there are only two considerations: The current state of the cell, and the states of the cells in its
# [Moore Neighbourhood][moore], the eight cells adjacent horizontally, vertically, or diagonally.
#
# Cafe au Life implements Conway's Game of Life, as well as other "[life-like][ll]" games in the same family.
#
# [ll]: http://www.conwaylife.com/wiki/Cellular_automaton#Well-known_Life-like_cellular_automata
# [moore]: http://en.wikipedia.org/wiki/Moore_neighborhood
# [source]: https://github.com/raganwald/cafeaulife/blob/master/lib
# [life]: http://en.wikipedia.org/wiki/Conway's_Game_of_Life
# [cs]: http://jashkenas.github.com/coffee-script/
# [node]: http://nodejs.org
#
# ## Why
#
# Cafe au Life is based on Bill Gosper's brilliant [HashLife][hl] algorithm. HashLife is usually implemented in C and optimized
# to run very long simulations with very large 'boards' stinking fast. The HashLife algorithm is, in a word,
# **a beautiful design**, one that is "in the book." To read its description is to feel the desire to explore it on a computer.
#
# Broadly speaking, HashLife has two major components. The first is a high level algorithm that is implementation independent.
# This algorithm exploits repetition and redundancy, aggressively 'caching' previously computed results for regions of the board.
# The second component is the cache itself, which is normally implemented cleverly in C to exploit memory and CPU efficiency
# in looking up precomputed results.
#
# Cafe au Life is an exercise in exploring the beauty of HashLife's recursive caching or results, while accepting that the
# performance in a JavaScript application will not be anything to write home about.
#
# [hl]: http://en.wikipedia.org/wiki/Hashlife

# ## How

# Cafe au Life is based on two very simple classes:
#
# The smallest unit of Life is the `Cell`. The constructor is set up to call an `initialize` method to make point-cuts slightly easier.
#
# HashLife operates on square regions of the board, with the length of the side of each square being a natural power of two
# (`2^1 -> 2`, `2^2 -> 4`, `2^3 -> 8`...). Naturally, squares are represented by instances of the class `Square`. The smallest possible square
# (of size `2^1`) has cells for each of its four quadrants, while all larger squares (of size `2^n`) have squares of one smaller
# size (`2^(n-1)`) for each of their four quadrants.
#
# For example, a square of size eight (`2^3`) is composed of four squares of size four (`2^2`):
#
#     nw         ne
#       ....|....
#       ....|....
#       ....|....
#       ....|....
#       ————#————
#       ....|....
#       ....|....
#       ....|....
#       ....|....
#     sw         se
#
# The squares of size four are in turn each composed of four squares of size two (`2^1`):
#
#     nw           ne
#       ..|..|..|..
#       ..|..|..|..
#       ——+——|——+——
#       ..|..|..|..
#       ..|..|..|..
#       —————#—————
#       ..|..|..|..
#       ..|..|..|..
#       ——+——|——+——
#       ..|..|..|..
#       ..|..|..|..
#     sw           se
#
# And those in turn are each composed of four cells, which cannot be subdivided. (For simplicity, a Cafe au Life
# board is represented as one such large square, although the HashLife algorithm can be used to handle any board shape by tiling it with squares.)
exports ?= window or this
_ = require('underscore')

class Cell
  constructor: (@value) ->
    @level = 0
    @initialize.apply(this, arguments)
  initialize: ->

class Square
  constructor: ({@nw, @ne, @se, @sw}) ->
    @level = @nw.level + 1
    @initialize.apply(this, arguments)
  initialize: ->

_.defaults exports, {Cell, Square}

# Cafe au Life is divided into modules:
#
# * The [Rules Module][rules] provides a method for setting up the [rules][ll] of the Life universe.
# * The [Future Module][future] provides methods for computing the future of a pattern, taking into account its ability to grow beyond
# the size of its container square.
# * The [Cache Module][cache] implements a very naive hash-table for canoncial representations of squares. HashLife uses extensive
# [canonicalization][canonical] to optimize the storage of very large patterns with repetitive components. **New**: Garbage collection
# allows Cafe au Life to compute the futur eof patterns with high entropy.
# * The [Garbage Collection Module][gc] implements a simple reference-counting garbage collector for the cache.
# * The [API Module][api] provides methods for grabbing json or strings of patterns and resizing them to fit expectations.
# * The [Menagerie Module][menagerie] provides a few well-know life objects predefined for you to play with. It is entirely optional.
#
# The modules will build up the functionality of our `Cell` and `Square` classes.
#
# [menagerie]: http:menagerie.html
# [api]: http:api.html
# [future]: http:future.html
# [cache]: http:cache.html
# [canonical]: https://en.wikipedia.org/wiki/Canonicalization
# [rules]: http:rules.html
# [gc]: http:gc.html
# [ll]: http://www.conwaylife.com/wiki/Cellular_automaton#Well-known_Life-like_cellular_automata

require('./rules').mixInto(exports)
require('./future').mixInto(exports)
require('./cache').mixInto(exports)
require('./gc').mixInto(exports)
require('./api').mixInto(exports)

# ## The first time through
#
# If this is your first time through the code, start with the [Rules Module][rules], and then read the [Future Module][future]
# to understand the core algorithm for computing the future of a pattern. You can look at the [Cache][cache] and [API][api] modules
# at your leisure.
#
# [menagerie]: http:menagerie.html
# [api]: http:api.html
# [future]: http:future.html
# [cache]: http:cache.html
# [canonical]: https://en.wikipedia.org/wiki/Canonicalization
# [rules]: http:rules.html

# ## Who
#
# When he's not shipping Ruby, Javascript and Java applications scaling out to millions of users,
# [Reg "Raganwald" Braithwaite](http://reginald.braythwayt.com) has authored libraries for Javascript and Ruby programming
# such as [Katy](https://github.com/raganwald/Katy), [JQuery Combinators](http://github.com/raganwald/JQuery-Combinators),
# [YouAreDaChef](https://github.com/raganwald/YouAreDaChef), [andand](http://github.com/raganwald/andand),
# and more you can find on [Github](https://github.com/raganwald).
#
# He has written three books:
#
# * [Kestrels, Quirky Birds, and Hopeless Egocentricity](http://leanpub.com/combinators): *Raganwald's collected adventures in Combinatory Logic and Ruby Meta-Programming*
# * [What I've Learned From Failure](http://leanpub.com/shippingsoftware): *A quarter-century of experience shipping software, distilled into fixnum bittersweet essays*
# * [How to Do What You Love & Earn What You’re Worth as a Programmer](http://leanpub.com/dowhatyoulove)
#
# His hands-on coding blog [Homoiconic](https://github.com/raganwald/homoiconic) frequently lights up the Hackerverse,
# and he also writes about [project management and other subjects](http://raganwald.posterous.com/).

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