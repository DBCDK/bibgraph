# ![logo](https://solsort.com/_logo.png) BibGraph visualisation

Visualisations of related books, based on the ADHL-data

Work in progress

# Roadmap

- embeddable code
- close visualisation on background click
- replace menu with:
    - pinned position when dragged
    - unpinned when clicked
    - generate graph based on pinned elements (size `k*sqrt(w*h)*log(numPinned)`)
    - later: ghosts from recently unpinned elements
- better traversal, starting in pinned elements
    - perhaps deterministic random, with separate bucket of nodes per pinned, and picked random from that
        - one seed generates seeds for each bucket, and and bucket elements generated one bucket at a time - in order, same element allowed in multible buckets, but only yields one box
    - expand node with certain deterministic probability, ie. each potential node put into large number of buckets, and then empty buckets in same permuted order. Ie. assign (salted) hashed number for each possible expand klyngeId, keep taking the one with the lowest number.
- encode expansions+fixedPoss in hash if not used for anything else
- mouse-handler-abstraction for touch

## Done
- weight links by `P(A|B)P(B|A)` instead of just `P(A|B)`, to avoid popular unrelated books pop up
- draggable books
- refactor/documentation
- better line drawing
- pinnable
- popup menu
- dynamic update of graph
- make it work in other than webkit

# Running:

Requires copy of the data `adhl.json` to run. (`adhl.json` contains one json per line, either `["faust", faust, klynge]` mapping between faust numbers and klynger, or `["adhl", klynge1, [[klynge1, count], [klynge2, count], ...]]` with the number of coloans for each klynge.

To load up the database run:

    python importdata.py
    coffee updateData.coffee

and then just run `coffee server.coffee` to which makes the http-server run on `localhost:1234`.

# Internal details

## REST API

- `/faust/$FAUST_ID` 
- `/klynge/$KLYNGE_ID`
- `/search/$QUERY`

## Database

Uses a single leveldb

- `faust:####` mapping from faustnumber to klynge + optional title
- `klynge:###` data about each klynge
