# Cafe au Life

**Achtung**! This is a work-in-progress. You're welcome to read along as I complete it, but please don't post the repository to sites like Hacker News or Proggit, at least not until there is actual working code. Thanks!

---

## What

Cafe au Life is an implementation of John Conway's [Game of Life][life] cellular automata written in [CoffeeScript][cs]. Cafe au Life runs on [Node.js][node], it is not designed to run as an interactive program in a browser window.

[life]: http://en.wikipedia.org/wiki/Conway's_Game_of_Life
[cs]: http://jashkenas.github.com/coffee-script/
[node]: http://nodejs.org

## Why

Cafe au Life is based on Bill Gosper's brilliant [HashLife][hl] algorithm. HashLife is usually implemented in C and optimized to run very long simulations with very large 'boards' stinking fast. [Golly][golly] is a fast Life simulator that contains, amongst other things, an implementation of HashLife written for raw speed.

[hl]: http://en.wikipedia.org/wiki/Hashlife
[golly]: http://golly.sourceforge.net/

Broadly speaking, HashLife has two major components. The first is a high level algorithm that is implementation independent. This algorithm exploits repetition and redundancy, aggressively 'caching' previously computed results for regions of the board. The second component is the cache itself, which is normally implemented cleverly in C to exploit memory and CPU efficiency in looking up precomputed results.

Cafe au Life is an exercise in exploring the beauty of HashLife's recursive caching or results, while accepting that the performance of the cache itself in a JavaScript application will not be anything to write home about.

HashLife is, in a word, a beautiful design, one that is "in the book." To read its description is to feel the desire to explore it on a computer.

## Whence

My understanding of HashLife was gleaned from the writings of:

* [Tony Finch explains HashLife](http://fanf.livejournal.com/83709.html)
* [An Algorithm for Compressing Space and Time](http://drdobbs.com/jvm/184406478)

## How

HashLife operates on square regions of the board, with the length of the side of each square being a natural power of two ( `2^0 -> 1`, `2^1 -> 2`, `2^2 -> 4`, `2^3 -> 8`...).

    class Square

### Subdivisions

One property of a square of size `2^n | n > 0` is that it can be divided into four component squares of size `2^(n-1)`. For example, a square of size eight (`2^3`) is composed of four component squares of size four (`2^2`):

    nw        ne  
      +--++--+
      |..||..|
      |..||..|
      +--++--+
      +--++--+
      |..||..|
      |..||..|
      +--++--+
    sw        se

The squares of size four are in turn each composed of four component squares of size two (`2^1`), which are each composed of four component squares of size one (`2^0`), which cannot be subdivided.(For simplicity, a Cafe au Life board is represented as one such large square, although the HashLife algorithm can be used to handle any board shape by tiling it with squares.)

HashLife exploits this symmetry by representing all squares of size `n > 0` as CoffeeScript class instances with four properties, conventionally labeled `nw`, `ne`, `se` and `sw`:

    class Divisible extends Square
      constructor: ({@nw, @ne, @se, @sw}) ->

(The technical name for such a data structure is a [QuadTree][qt].)

[qt]: http://en.wikipedia.org/wiki/Quadtree

### Representing squares

The key principle behind HashLife is taking advantage of redundancy. Therefore, two squares with the same alive and dead cells are always represented by the same, immutable square object. There is no concept of an array or bitmap of cells except when performing import and export.

Squares of size `0` are represented as either of:

    class Indivisible extends Square
      constructor: ({@if_alive, @if_dead})
  
    Alive = new Indivisible
      if_alive: (fn) -> fn.call(this)
      if_dead: (fn) ->
    
    Dead = new Indivisible
      if_alive: (fn) ->
      if_dead: (fn) -> fn.call(this)
      
In addition to initializing `Alive` and `Dead`, Cafe au Life pre-initializes the sixteen possible squares of size two:

    squares_0 = [Dead, Alive]
    
    squares_1 = (0..15).map (n) ->
      new Divisible
        nw: squares_0[(n&8)>>3]
        ne: squares_0[(n&4)>>2]
        se: squares_0[(n&2)>>1]
        sw: squares_0[n&1]

For example, a square of size thirty-two (`2^5`) consisting of entirely dead cells would have its `nw`, `ne`, `se`, and `sw` properties all containing the same square of size sixteen (`2^4`). That square would have its four properties containing the same square of size eight (`2^3`), which would have its four properties containing the same square of size four, which in turn would have all four if its properties containing the same square of size two, and that square would have four properties, all containing the size zero value `Dead`.

Thus, a board containing 1,024 cells could be represented by as few as six objects when there is maximal redundancy. This saves more than space: HashLife is able to cache the result of iterating forward in time with each square. HashLife thus trades a huge amount of calculation for cache lookups.

### The Speed of Light

In Life, the "Speed of Light" or "*c*" is one cell vertically, horizontally, or diagonally in any direction. Meaning, that cause and effect cannot travel faster than *c*.

One consequence of this fundamental limit is that given a square of size `2^n | n > 1` at time `t`, HashLife has all the information it needs to calculate the alive and dead cells for the inner square of size `2^n - 2` at time `t+1`. For example, if HashLife has this square at time `t`:

    nw        ne  
      +--++--+
      |..||..|
      |..||..|
      +--++--+
      +--++--+
      |..||..|
      |..||..|
      +--++--+
    sw        se

HashLife can calculate this square at time `t+1`:

    nw        ne
    
       +----+
       |....|
       |....|
       |....|
       |....|
       +----+
       
    sw        se

And this square at time `t+2`:

    nw        ne
    
    
        +--+
        |..|
        |..|
        +--+
        
       
    sw        se

And this square at time `t+3`:

    nw        ne
    
    
        
         ++
         ++
        
        
       
    sw        se
    

This is because no matter what is in the cells surrounding our square, their effects cannot propagate faster than the speed of light, one row inward from the edge every step in time.

HashLife takes advantage of this by storing enough information to quickly look up the shrinking 'future' for every square of size `2^n | n > 1`. The information is called a square's *result*.

### Computing the result for squares

Let's revisit the obvious: Squares of size one and two do not have results, because at time `t+1`, cells outside of the square will affect every cell in the square.

The smallest square that computes a result is of size four (`2^2`). Its result is a square of size two (`2^1`) representing the state of those cells at time `t+1`:

    ....
    .++.
    .++.
    ....

The computation of the four inner `+` cells from their adjacent eight cells is straightforward and can be calculated from the basic 2-3 rules or looked up from a table with 65K entries. Thus, the result of a square of size four is a square of size two representing the state of the center at time `t+1`.

Since the result represents the state one 'moment' later, we say the result has a *velocity* of one. (We will see later that larger squares will have higher velocities.)

Cafe au Life initializes the results for squares of size four with a seed array of all 65536 possible squares and their results:

    class SquareSz4 extends Divisible
      constructor({nw, ne, se, sw, @result}) ->
        super({nw: nw, ne:ne, se:se, sw:sw})
        @velocity = 1

    [
      [ 0,  0,  0,  0, 0],
      # ...
      [15, 15, 15, 15, 0]
    ].each ([nw, ne, se, sw, result]) ->
      new SquareSz4
        nw: squares_1[nw]
        ne: squares_1[ne]
        se: squares_1[se]
        sw: squares_1[sw]
        result: squares_1[result]

### Squares of size eight

Now let's consider a square of size eight. First, we are going to assume that we can look up any `Divisible` square from the cache with the following method:

    Square.find({ nw: ..., ne: ..., se: ..., sw: ...})

Given four component squares, this looks up a square in the cache. For the moment, we can ignore the question of what happens when a square is not in the cache, because when dealing with squares of size eight, we only ever need to look up squares of size four, and they are all seeded in the cache. (Once we have established how to construct the result for a square of size eight, including its result and velocity, we will be able to write out `.find` method to handle looking up squares of size eight and dealing with cache 'misses' by constructing a new square.)

We know how to obtain any square of size four using `Square.find`. So what we need is a way to compute the result for any arbitrary square of size eight from squares of size four.

First, Let's look at our square of size eight made up of four component squares of size four:

    nw        ne  
      +--++--+
      |..||..|
      |..||..|
      +--++--+
      +--++--+
      |..||..|
      |..||..|
      +--++--+
    sw        se

Given that we know the result for each of those four squares, we can start building an intermediate result. In this diagram, we have labeled the results by their source:

    nw        ne
    
       nw..ne
       nw..ne
       ......
       ......
       sw..se
       sw..se
       
    sw        se
    
As we go along, we'll complete this bit of code:

    class Square3 extends Square
      constructor: ({nw, ne, se, sw}) ->
        super({nw: nw, ne:ne, se:se, sw:sw})
        
        this_to_intermediate_components = ->
          nw: @nw.result
          ne: @ne.result
          se: @se.result
          sw: @sw.result
          # ...
          
We can also derive four overlapping squares, these representing `n`, `e`, `s`, and `w`:

         nn             
      ..+--+..        ..+--+..
      ..|..|..        ..|..|..
      +-|..|-+        +--++--+
      |.+--+.|      w |..||..| e
      |.+--+.|      w |..||..| e
      +-|..|-+        +--++--+
      ..|..|..        ..|..|..
      ..+--+..        ..+--+..
         ss
         
Deriving these from our four component squares is straightforward, and when we take their results, we fill in four of the five missing blanks (we haven't actually constructed something yet, we're just noting how these pieces relate to each other):

    nw        ne
    
       ..nn..
       ..nn..
       ww..ee
       ww..ee
       ..ss..
       ..ss..
       
    sw        se
    
We add this into our code:

          # ...
          
          nn: Square
            .find
              nw: @nw.ne
              ne: @ne.nw
              se: @ne.sw
              sw: @nw.se
            .result
          ee: Square
            .find
              nw: @ne.sw
              ne: @ne.se
              se: @se.ne
              sw: @se.nw
            .result
          ss: Square
            .find
              nw: @sw.ne
              ne: @se.nw
              se: @se.sw
              sw: @sw.se
            .result
          ww: Square
            .find
              nw: @nw.sw
              ne: @nw.se
              se: @se.ne
              sw: @se.nw
            .result
            
          # ...

We use a similar method to derive a center square:

    nw        ne
    
       ......
       .+--+.
       .|..|.
       .|..|.
       .+--+.
       ......
       
    sw        se
    
And we extract its result square accordingly:

          # ...
          
          cc: Square
            .find
              nw: @nw.se
              ne: @ne.sw
              se: @se.nw
              sw: @sw.ne
            .result


    nw        ne
    
       ......
       ......
       ..cc..
       ..cc..
       ......
       ......
       
    sw        se

We have now derived nine squares of size `2^(n-1)`: Four component squares and five we have derived from second-order components. The results we have extracted have all been cached, so we are performing lookups rather than computations.

These squares fit together to make a larger intermediate square, one that does not neatly fit into our world of `2^n` quanta:

    nw        ne
    
       nwnnne
       nwnnne
       wwccee
       wwccee
       swssse
       swssse
       
    sw        se

To make our algorithm scale recursively, we can't use a square that has a different geometric relationship for squares of size eight than squares of size four. We need a square of size `2^(n-1)`. The simplest solution would be to simply trim what we have:

    nw        ne

    
        wnnn
        wcce
        wcce
        wsss

       
    sw        se
    
This involves digging inside of our results and recombining their pieces. If we're going to do that, we might as well get something in return. So instead of trimming the square to get a smaller square with the same velocity, we're going to take another step forward in time:

### a step in time

Let's revisit our intermediate result:

    nw        ne
    
       nwnnne
       nwnnne
       wwccee
       wwccee
       swssse
       swssse
       
    sw        se
    
From this, we can make four *overlapping* squares of size `2^(n-1)`:

    nw        ne  nw        ne
    
       nwnn..        ..nnne
       nwnn..        ..nnne
       wwcc..        ..ccee
       wwcc..        ..ccee
       ......        ......
       ......        ......
       
    sw        se  sw        se
    
    nw        ne  nw        ne
    
       ......        ......
       ......        ......
       wwcc..        ..ccee
       wwcc..        ..ccee
       swss..        ..ssse
       swss..        ..ssse
       
    sw        se  sw        se
    
Note that these overlapping squares can all be built out of our intermediate results. So let's do that:
    
    square_to_overlaps = ->
      nw: Square
        .find
          nw: @nw
          ne: @nn
          se: @cc
          sw: @ww
      ne: Square
          .find
          nw: @nn
          ne: @ne
          se: @ee
          sw: @cc
      se: Square
        .find
          nw: @cc
          ne: @ee
          se: @se
          sw: @ss
      sw: Square
        .find
          nw: @ww
          ne: @cc
          se: @ss
          sw: @sw
        
What do we do with our four overlaps? Why, we get *their* results, of course. Let's revise our snippet:
    
    intermediate_components_to_result_components = ->
      nw: Square
        .find
          nw: @nw
          ne: @nn
          se: @cc
          sw: @ww
        .result
      ne: Square
          .find
          nw: @nn
          ne: @ne
          se: @ee
          sw: @cc
        .result
      se: Square
        .find
          nw: @cc
          ne: @ee
          se: @se
          sw: @ss
        .result
      sw: Square
        .find
          nw: @ww
          ne: @cc
          se: @ss
          sw: @sw
        .result

This produces:

    nw        ne
    
       ......
       .nwne.
       .nwne.
       .swse.
       .swse.
       ......
       
    sw        se

And when we place it within our original square of size eight, we reveal we have a square of size four, `2^(n=-1)` as we wanted

    nw        ne
      ........
      ........
      ..nwne..
      ..nwne..
      ..swse..
      ..swse..
      ........
      ........
    sw        se

Obviously, we can make a square out of that:

    intermediate_square_components = this_to_intermediate_components.call(this)
    result_square_components = intermediate_components_to_result_components.call(intermediate_square_components)

    @result = Square.find(result_square_components)
    
What about our velocity? Well, we have taken *two* steps forward in time, not one. Both steps were the same size as the velocity of squares of size `2^(n-1)`, so let's grab one such square's velocity and double it:

    @velocity = @nw.velocity * 2