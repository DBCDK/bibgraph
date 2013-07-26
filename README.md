# ![logo](https://solsort.com/_logo.png) BibGraph visualisation

Visualisations of related books, based on the ADHL-data

Work in progress

# Roadmap

- weight links by `P(A|B)P(B|A)` instead of just `P(A|B)`, to avoid popular unrelated books pop up
- traversal not random, but 6-3-3 or something similar initially
    - and corresponding links
- dynamic update of graph
- clickable books with popup-menu
    - increase number of links by 3
    - pin it
    - decrease number of links by 3
    - link to bibliotek.dk
    - close visualisation
- dragable books
- refactor/documentation
- embeddable code
- better line drawing

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
