# Cafe au Life

Cafe au Life is an implementation of John Conway's [Game of Life][life] cellular automata written in [CoffeeScript][cs]. Cafe au Life runs on [Node.js][node], it is not designed to run as an interactive program in a browser window.

[life]: http://en.wikipedia.org/wiki/Conway's_Game_of_Life
[cs]: http://jashkenas.github.com/coffee-script/
[node]: http://nodejs.org

Cafe au Life's annotated source code is [here](http://raganwald.github.com/cafeaulife/docs/cafeaulife.html).

## What

![Gosper's Glider Gun](http://raganwald.github.com/cafeaulife/doc/gospers_glider_gun.gif)

*(Gosper's Glider Gun. This was the first gun discovered, and proved that Life patterns can grow indefiniately.)*

Cafe au Life is an implementation of John Conway's [Game of Life][life] cellular automata written in [CoffeeScript][cs].
Cafe au Life runs on [Node.js][node], it is not designed to run as an interactive program in a browser window.

[life]: http://en.wikipedia.org/wiki/Conway's_Game_of_Life
[cs]: http://jashkenas.github.com/coffee-script/
[node]: http://nodejs.org

### Conway's Life and other two-dimensional cellular automata

The Life Universe is an infinite two-dimensional matrix of cells. Cells are indivisible and are in either of two states,
commonly called "alive" and "dead." Time is represented as discrete quanta called either "ticks" or "generations."
With each generation, a rule is applied to decide the state the cell will assume. The rules are decided simultaneously,
and there are only two considerations: The current state of the cell, and the states of the cells in its
[Moore Neighbourhood][moore], the eight cells adjacent horizontally, vertically, or diagonally.

Cafe au Life implements Conway's Game of Life, as well as other "[life-like][ll]" games in the same family.

[ll]: http://www.conwaylife.com/wiki/Cellular_automaton#Well-known_Life-like_cellular_automata
[moore]: http://en.wikipedia.org/wiki/Moore_neighborhood

## Why

![Period 24 Glider Gun](http://raganwald.github.com/cafeaulife/doc/Trueperiod24gun.png)

*(A period 24 Glider Gun. Gliders of different periods are useful for synchronizing signals in complex
Life machines.)*

Cafe au Life is based on Bill Gosper's brilliant [HashLife][hl] algorithm. HashLife is usually implemented in C and optimized
to run very long simulations with very large 'boards' stinking fast. The HashLife algorithm is, in a word,
**a beautiful design**, one that is "in the book." To read its description is to feel the desire to explore it on a computer.

Broadly speaking, HashLife has two major components. The first is a high level algorithm that is implementation independent.
This algorithm exploits repetition and redundancy, aggressively 'caching' previously computed results for regions of the board.
The second component is the cache itself, which is normally implemented cleverly in C to exploit memory and CPU efficiency
in looking up precomputed results.

Cafe au Life is an exercise in exploring the beauty of HashLife's recursive caching or results, while accepting that the
performance in a JavaScript application will not be anything to write home about.

[hl]: http://en.wikipedia.org/wiki/Hashlife

My understanding of HashLife was gleaned from the writings of:

* [Tony Finch explains HashLife](http://fanf.livejournal.com/83709.html)
* [An Algorithm for Compressing Space and Time](http://drdobbs.com/jvm/184406478)
* [Golly][golly] is a fast Life simulator that contains, amongst other things, an implementation of HashLife written for raw speed.

[golly]: http://golly.sourceforge.net/