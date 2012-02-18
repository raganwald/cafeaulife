# Cafe au Life

![Gosper's Glider Gun](http://raganwald.github.com/cafeaulife/docs/gospers_glider_gun.gif)

*(Gosper's Glider Gun. This was the first gun discovered, and proved that Life patterns can grow indefinitely.)*

Cafe au Life is an implementation of John Conway's [Game of Life][life] cellular automata written in [CoffeeScript][cs]. Cafe au Life runs on [Node.js][node], it is not designed to run as an interactive program in a browser window.

[life]: http://en.wikipedia.org/wiki/Conway's_Game_of_Life
[cs]: http://jashkenas.github.com/coffee-script/
[node]: http://nodejs.org

Cafe au Life's annotated source code is [here](http://raganwald.github.com/cafeaulife/docs/cafeaulife.html). It contains the full explanation of the algorithm, and most of the stuff you'd normally find interesting in a README file.

### Playing with Cafe au Life

The easiest way to try Cafe au Life is to clone the repository, then use CoffeeScript's `coffee` command:

```bash
raganwald@Reginald-Braithwaites-iMac[cafeaulife (master)⚡] coffee
coffee> Life = require('./lib/cafeaulife').set_universe_rules()
{ Cell: 
   { [Function: Cell]
     Alive: { value: 1, id: 1, population: 1 },
     Dead: { value: 0, id: 2, population: 0 } },
  Square: 
   { [Function: Square]
     Intermediate: [Function: Intermediate],
     cache: 
      { buckets: [Object],
        clear: [Function],
        bucketed: [Function],
        find: [Function],
        add: [Function],
        current_rules: [Object] },
     canonicalize: [Function],
     from_json: [Function] },
  RecursivelyComputableSquare: 
   { [Function: RecursivelyComputableSquare]
     Intermediate: [Function: Intermediate],
     __super__: 
      { initialize: [Function],
        intermediate_via_subresults: [Functio
        result_at_time_zero: [Function],
        result_at_time: [Function],
        empty_copy: [Function],
        pad_by: [Function],
        future_at_time: [Function],
        trim: [Function] } },
  set_universe_rules: [Function] }n],
        intermediate_via_crop: [Function],
```
Now you can try things on the command line:

```bash
coffee> r = Life.Square.from_json [ \
                [0, 0, 0, 0]       \
                [0, 1, 0, 0]       \
                [1, 1, 1, 0]       \
                [0, 0, 1, 0] ]
{ nw: 
   { nw: { value: 0, id: 2, population: 0 },
     ne: { value: 0, id: 2, population: 0 },
     se: { value: 1, id: 1, population: 1 },
     sw: { value: 0, id: 2, population: 0 },
     id: 7,
     level: 1,
     subsquares_via_crop: [Function],
     subsquares_via_subresults: [Function],
     to_json: [Function],
     toString: [Function],
     isEmpty: [Function],
     population: 1 },
  ne: 
   { nw: { value: 0, id: 2, population: 0 },
     ne: { value: 0, id: 2, population: 0 },
     se: { value: 0, id: 2, population: 0 },
     sw: { value: 0, id: 2, population: 0 },
     id: 3,
     level: 1,
     subsquares_via_crop: [Function],
     subsquares_via_subresults: [Function],
     to_json: [Function],
     toString: [Function],
     isEmpty: [Function],
     population: 0 },
  se: 
   { nw: { value: 1, id: 1, population: 1 },
     ne: { value: 0, id: 2, population: 0 },
     se: { value: 0, id: 2, population: 0 },
     sw: { value: 1, id: 1, population: 1 },
     id: 12,
     level: 1,
     subsquares_via_crop: [Function],
     subsquares_via_subresults: [Function],
     to_json: [Function],
     toString: [Function],
     isEmpty: [Function],
     population: 2 },
  sw: 
   { nw: { value: 1, id: 1, population: 1 },
     ne: { value: 1, id: 1, population: 1 },
     se: { value: 0, id: 2, population: 0 },
     sw: { value: 0, id: 2, population: 0 },
     id: 6,
     level: 1,
     subsquares_via_crop: [Function],
     subsquares_via_subresults: [Function],
     to_json: [Function],
     toString: [Function],
     isEmpty: [Function],
     population: 2 },
  id: 14615,
  level: 2,
  subsquares_via_crop: [Function],
  subsquares_via_subresults: [Function],
  to_json: [Function],
  toString: [Function],
  isEmpty: [Function],
  population: 5,
  result: 
   { nw: { value: 1, id: 1, population: 1 },
     ne: { value: 1, id: 1, population: 1 },
     se: { value: 1, id: 1, population: 1 },
     sw: { value: 0, id: 2, population: 0 },
     id: 10,
     level: 1,
     subsquares_via_crop: [Function],
     subsquares_via_subresults: [Function],
     to_json: [Function],
     toString: [Function],
     isEmpty: [Function],
     population: 3 } }
coffee>  r.future_at_time(1073741824).population
116
coffee> r.future_at_time(17179869184).trim().level
33
coffee> 
```

Have fun!

### Is it any good?

[Yes](http://news.ycombinator.com/item?id=3067434).