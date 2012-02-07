# # Cafe au Life

## What

# Cafe au Life is an implementation of John Conway's [Game of Life][life] cellular automata
# written in [CoffeeScript][cs]. Cafe au Life runs on [Node.js][node], it is not designed
# to run as an interactive program in a browser window.
#
# Cafe au Life's Github project is [here](https://github.com/raganwald/cafeaulife/). This file,
# [cafeaulife.coffee][source] contains the core engine for computing the future of any life universe
# of size `2^n | n > 1`. The algorithm is optimized for computing very large numbers of generations
#  of very large and complex life patterns with a high degree of regularity such as implementing
# Turing machines.
#
# As such, it is particularly poorly suited for animating displays a generation at a time. But it
# is still a beautiful algorithm that touches on the soul of life’s “physics."
#
# ![Gosper's Glider Gun](http://raganwald.github.com/cafeaulife/docs/gospers_glider_gun.gif)
#
# *(Gosper's Glider Gun. This was the first gun discovered, and proved that Life patterns can grow indefinitely.)*
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
# [source]: https://github.com/raganwald/cafeaulife/blob/master/lib/cafeaulife.coffee
# [life]: http://en.wikipedia.org/wiki/Conway's_Game_of_Life
# [cs]: http://jashkenas.github.com/coffee-script/
# [node]: http://nodejs.org
#
# ## Why
#
# ![Period 24 Glider Gun](http://raganwald.github.com/cafeaulife/docs/Trueperiod24gun.png)
#
# *(A period 24 Glider Gun. Gliders of different periods are useful for synchronizing signals in complex
# Life machines.)*
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

# Cafe au Life is divided into three modules. Each modules' title is a link to its annotated source code.:

# The [Base Module][base] provides the `Cell` and `Square` classes, including `RecursivelyComputableSquare`, the foundation of the
# HashLife implementation.
#
# [base]: http:base.html
module.exports = require('./base')

# The [Rules Module][rules] provides a method for setting up the [rules][ll] of the Life universe.
#
# [rules]: http:rules.html
# [ll]: http://www.conwaylife.com/wiki/Cellular_automaton#Well-known_Life-like_cellular_automata
require('./rules').mixInto(module.exports)

# HashLife uses extensive [canonicalization][canonical] to optimize the storage of very large patterns with repetitive
# components. The [Cache Module][cache] implementss a very naive hash-table for canoncial representations of squares.
#
# [cache]: http:cache.html
# [canonical]: https://en.wikipedia.org/wiki/Canonicalization
require('./cache').mixInto(module.exports)

# The [API Module][api] provides methods for computing the future of a pattern, taking into account its ability to grow beyond
# the size of its container square.
#
# [api]: http:api.html
require('./api').mixInto(module.exports)

# The [Future Module][future] provides methods for computing the future of a pattern, taking into account its ability to grow beyond
# the size of its container square.
#
# [future]: http:future.html
require('./future').mixInto(module.exports)

# ## Who
#
# When he's not shipping Ruby, Javascript and Java applications scaling out to millions of users,
# [Reg "Raganwald" Braithwaite](http://reginald.braythwayt.com) has authored libraries for Javascript and Ruby programming
# such as [Katy](https://github.com/raganwald/Katy), [JQuery Combinators](http://github.com/raganwald/JQuery-Combinators),
# [YouAreDaChef](https://github.com/raganwald/YouAreDaChef), [andand](http://github.com/raganwald/andand),
# and more you can find on [Github](https://github.com/raganwald).
#
# He has written two books:
#
# * [Kestrels, Quirky Birds, and Hopeless Egocentricity](http://leanpub.com/combinators): *Raganwald's collected adventures in Combinatory Logic and Ruby Meta-Programming*
# * [What I've Learned From Failure](http://leanpub.com/shippingsoftware): *A quarter-century of experience shipping software, distilled into fixnum bittersweet essays*
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