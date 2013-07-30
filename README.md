# ![logo](https://solsort.com/_logo.png) BibGraph visualisation

Visualisations of related books, based on the ADHL-data

Work in progress

# Roadmap

- disable for ie8 and older (works with ie9+)
- touch-events
- pinned initial book
- better landing/info-page
    - bibdk serach box
    - exmaples
    - introduction to the project
    - features
    - documentation
    - layout via bootstrap
- encode expansions+fixedPoss in hash if not used for anything else

## Done
- weight links by `P(A|B)P(B|A)` instead of just `P(A|B)`, to avoid popular unrelated books pop up
- draggable books
- refactor/documentation
- better line drawing
- pinnable
- popup menu
- embeddable code
- replace menu with:
    - pinned position when dragged
    - unpinned when clicked
    - generate graph based on pinned elements 
- dynamic update of graph
- make it work in other than webkit
- close visualisation on background click
- better traversal, starting in pinned elements
    - perhaps deterministic random, with separate bucket of nodes per pinned, and picked random from that
        - one seed generates seeds for each bucket, and and bucket elements generated one bucket at a time - in order, same element allowed in multible buckets, but only yields one box
        - probability for low-probability co-loans to avoid getting stuck in local cluster

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
