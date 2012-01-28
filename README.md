# Cafe au Life

**Achtung**! This is a work-in-progress. You're welcome to read along as I complete it, but please don't post the repository to sites like Hacker News or Proggit, at least not until there is actual working code. Thanks!

---

## What

Cafe au Life is an implementation of John Conway's [Game of Life][life] cellular automata written in [CoffeeScript][cs]. Cafe au Life runs on [Node.js][node], it is not designed to run as an interactive program in a browser window.

[life]: http://en.wikipedia.org/wiki/Conway's_Game_of_Life
[cs]: http://jashkenas.github.com/coffee-script/
[node]: http://nodejs.org

The Life Universe is an infinite two-dimensional matrix of cells. Cells are indivisible and are in either of two states, commnly called "alive" and "dead." Time is represented as discrete quanta called either "ticks" or "generations." With each generation, a rule is applied to decide the state the cell will assume. The rules are decided simultaneously, and there are only two considerations: The current state of the cell, and the states of the cells in its [Moore Neighbourhood][moore], the eight cells adjacent horizontally, vertically, or diagonally.

[moore]: http://en.wikipedia.org/wiki/Moore_neighborhood

Cafe au Life implements Conway's Game of Life, as well as other "[life-like][ll]" games in the same family.

[ll]: http://www.conwaylife.com/wiki/Cellular_automaton#Well-known_Life-like_cellular_automata

## Why

Cafe au Life is based on Bill Gosper's brilliant [HashLife][hl] algorithm. HashLife is usually implemented in C and optimized to run very long simulations with very large 'boards' stinking fast. The HashLife algorithm is, in a word, **a beautiful design**, one that is "in the book." To read its description is to feel the desire to explore it on a computer.

[hl]: http://en.wikipedia.org/wiki/Hashlife

Broadly speaking, HashLife has two major components. The first is a high level algorithm that is implementation independent. This algorithm exploits repetition and redundancy, aggressively 'caching' previously computed results for regions of the board. The second component is the cache itself, which is normally implemented cleverly in C to exploit memory and CPU efficiency in looking up precomputed results.

Cafe au Life is an exercise in exploring the beauty of HashLife's recursive caching or results, while accepting that the performance of the cache itself in a JavaScript application will not be anything to write home about.

## How

HashLife operates on square regions of the board, with the length of the side of each square being a natural power of two (`2^1 -> 2`, `2^2 -> 4`, `2^3 -> 8`...). Cells are not considered squares. Therefore, the smallest possible square (of size `2^1`) has four cells as its quadrants, while all larger squares (of size `2^n`) have squares of one smaller size (`2^(n-1)`) as their quadrants. For example, a square of size eight (`2^3`) is composed of four squares of size four (`2^2`):

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

The squares of size four are in turn each composed of four squares of size two (`2^1`), which are each composed of four cells, which cannot be subdivided. (For simplicity, a Cafe au Life board is represented as one such large square, although the HashLife algorithm can be used to handle any board shape by tiling it with squares.)

[qt]: http://en.wikipedia.org/wiki/Quadtree

### Representing squares

The key principle behind HashLife is taking advantage of redundancy. Therefore, two squares with the same alive and dead cells are always represented by the same, immutable square objects. HashLife exploits repetition and redundancy by making all squares idempotent and unique. In other words, if two squares contain the same sequence of cells, they are represented by the same instance of class `Square`. For example, there is exactly one representation of a cell of size two containing four empty cells:

    nw  ne
      ..
      ..
    sw  sw

HashLife represents this as a structure with four quadrants, each of which is the canonical representation of an empty cell. In pseudo-CoffeeScript:

```coffeescript
empty_n_1 = Square.find_or_create_by_quadrant
  nw: Cell.Empty
  ne: Cell.Empty
  se: Cell.Empty
  sw: Cell.empty
```

Thus, a square of size four that represents sixteen empty cells is actually represented as a structure with four quadrants, each of which is the canonical representation of the empty square of size four:

    nw  ne
      ..
      ..
    sw  sw
    
```coffeescript
empty_n_2 = Square.find_or_create_by_quadrant
  nw: empty_n_1
  ne: empty_n_1
  se: empty_n_1
  sw: empty_n_1
```

Since squares are immutable, HashLife does not change the quadrants of a square when moving forward or backwards in time, it simply creates and/or selects squares representing the new generation's state.

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

The computation of the four inner `+` cells from their adjacent eight cells is straightforward and can be calculated from the basic 2-3 rules or looked up from a table with 65K entries. Thus, the result of a square of size four is a square of size two representing the state of the centre at time `t+1`. Since the result represents the state one 'moment' later, we say the result is one generation into the future. (We will see later that larger squares results more generations into the future.)

### Seeding

For reasons we will hand-wave now, Cafe au Life is "seeded" with the two possible squares of size one (Alive and Dead), the sixteen possible squares of size two, and the 65K possible squares of size four. The results for the squares of size four are computed using Life's rules.

Since each square of size four is unique, HashLife never needs to recompute the same sixteen-by-sixteen pattern. This makes a number of optimizations moot. For example, it is easy to note that the result of an empty square is also empty, but since this will only ever be computed once, why bother?

Squares of size eight and larger could be computed and their results memoized, but there are further optimizations to be had by exploiting redundancy.

### Squares of size eight

Now let's consider a square of size eight. For the moment, we can ignore the question of what happens when a square is not in the cache, because when dealing with squares of size eight, we only ever need to look up squares of size four, and they are all seeded in the cache. (Once we have established how to construct the result for a square of size eight, including its result and velocity, we will be able to write out `.find` method to handle looking up squares of size eight and dealing with cache 'misses' by constructing a new square.)

We know how to obtain any square of size four using `Square.find`. So what we need is a way to compute the result for any arbitrary square of size eight from squares of size four.

First, Let's look at our square of size eight made up of four component squares of size four (the lines and crosses are part of the components):

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

Our goal is to compute a result that looks like this (the lines and crosses are part of the result):

    nw        ne  

        +--+
        |..|
        |..|
        +--+

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
    
Note that these overlapping squares can all be built out of our intermediate results. We can now derive results from each of those squares:

    nw        ne
    
       ......
       .nwne.
       .nwne.
       .swse.
       .swse.
       ......
       
    sw        se

And when we place it within our original square of size eight, we reveal we have a square of size four, `2^(n-1)` as we wanted

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

### Memoizing: The "Hash" in HashLife

HashLife gets a tremendous speed-up by storing and reusing squares in a giant cache. Any result, at any scale, that has been computed before is reused. This is extremely efficient when dealing with patterns that contain a great deal of redundancy, such as the kinds of patterns constructed for the purpose of emulating circuits or machines in Life.

For example, once Cafe au Life has calculated the results for the 65K possible four-by-four squares, the rules are no longer applied to any generation: Any pattern of any size is recursively computed terminating in a four-by-four square that has already been computed and cached.

## Whence

My understanding of HashLife was gleaned from the writings of:

* [Tony Finch explains HashLife](http://fanf.livejournal.com/83709.html)
* [An Algorithm for Compressing Space and Time](http://drdobbs.com/jvm/184406478)
* [Golly][golly] is a fast Life simulator that contains, amongst other things, an implementation of HashLife written for raw speed.

[golly]: http://golly.sourceforge.net/