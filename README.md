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

...

coffee> r = Life.Square.from_json [ \
                [0, 0, 0, 0]       \
                [0, 1, 0, 0]       \
                [1, 1, 1, 0]       \
                [0, 0, 1, 0] ]
                
...

coffee> r.future_at_time(1103).population
116
coffee> gun = require('./lib/menagerie').gospers_glider_gun

...

gun.future_at_time(1099511627776).population
183251938004
```

Have fun!

### Is it any good?

[Yes](http://news.ycombinator.com/item?id=3067434).