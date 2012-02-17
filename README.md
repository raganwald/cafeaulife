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
coffee> Life = require('./lib/cafeaulife')
{ Cell: [Function: Cell],
  Square: 
   { [Function: Square]
     Intermediate: [Function: Intermediate],
     set_universe_rules: [Function],
     cache: 
      { num_buckets: 7919,
        buckets: [],
        clear: [Function],
        hash: [Function],
        hash_string: [Function],
        find: [Function],
        canonicalize_by_quadrant: [Function],
        canonicalize_by_json: [Function],
        canonicalize: [Function],
        add: [Function],
        bucketed: [Function],
        histogram: [Function] },
     canonicalize: [Function] },
  RecursivelyComputableSquare: 
   { [Function: RecursivelyComputableSquare]
     Intermediate: [Function: Intermediate],
     __super__: 
      { initialize: [Function],
        intermediate_via_subresults: [Function],
        intermediate_via_crop: [Function],
        result_at_time_zero: [Function],
        result_at_time: [Function],
        empty_copy: [Function],
        pad_by: [Function],
        future_at_time: [Function],
        crop: [Function],
        trim: [Function] } } }
coffee> Life.Square.set_universe_rules()
{ survival: [ 2, 3 ],
  birth: [ 3 ] }
coffee> 
```
Now you can try things on the command line:

```bash
coffee> r = Life.Square.canonicalize [ \
......>         [0, 0, 0, 0]       \
......>         [0, 1, 0, 0]       \
......>         [1, 1, 1, 0]       \
......>         [0, 0, 1, 0]       \
......>       ]
{ nw: 
   { nw: { value: 0, hash: 0 },
     ne: { value: 0, hash: 0 },
     se: { value: 1, hash: 1 },
     sw: { value: 0, hash: 0 },
     hash: 79,
     level: 1,
     to_json: [Function],
     toString: [Function],
     isEmpty: [Function] },
  ne: 
   { nw: { value: 0, hash: 0 },
     ne: { value: 0, hash: 0 },
     se: { value: 0, hash: 0 },
     sw: { value: 0, hash: 0 },
     hash: 0,
     level: 1,
     to_json: [Function],
     toString: [Function],
     isEmpty: [Function] },
  se: 
   { nw: { value: 1, hash: 1 },
     ne: { value: 0, hash: 0 },
     se: { value: 0, hash: 0 },
     sw: { value: 1, hash: 1 },
     hash: 38,
     level: 1,
     to_json: [Function],
     toString: [Function],
     isEmpty: [Function] },
  sw: 
   { nw: { value: 1, hash: 1 },
     ne: { value: 1, hash: 1 },
     se: { value: 0, hash: 0 },
     sw: { value: 0, hash: 0 },
     hash: 4,
     level: 1,
     to_json: [Function],
     toString: [Function],
     isEmpty: [Function] },
  hash: 3229,
  level: 2,
  to_json: [Function],
  toString: [Function],
  isEmpty: [Function],
  generations: 1,
  result: [Function] }
coffee> console?.log r.future_at_time(100).trim().toString()
```

Have fun!

### Is it any good?

[Yes](http://news.ycombinator.com/item?id=3067434).