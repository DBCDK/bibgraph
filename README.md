# ![.](https://solsort.com/_github_statistics.gif) BibGraph visualisation

Visualisering til at græsse rundt i relateret litteratur udregnet ud fra Andre Der Har Lånt (ADHL) data.

Bemærk: dette er en _eksperimentel prototype_ udviklet af DBC.
Ikke brugbar uden udtræk DBCs ADHL-datasæt.

# Installation

Installationen forudsætter node.js `npm` og python `pip`.

Repositoriet tjekkes ud (de følgende kommandoer antager man står i den udtjekkede mappe).

    git clone git@github.com:DBCDK/bibgraph.git
    cd bibgraph

Afhængigheder installeres via:

    npm install
    pip install leveldb

Databasen initialiseres med følgende kommandoer, hvilket tager noget tid:

    scp guesstimate:~rje/adhl.json .
    python importdata.py
    node ./node_modules/.bin/coffee updateData.coffee

Serveren startes herefter med:

    node ./node_modules/.bin/coffee server.coffee

hvorefter den burde være tilgængelig på `localhost:1234`

# Indlejring i website

Koden er designet til let at kunne blive integreret i biblioteks-webgrænseflade i fremtiden. 
Integration kommet til at gøres ved at der forekommer html-elementer med css-klassen `bibgraphRequest`, samt en `data-faust="..."` property. 

Scriptet vil da løbe siden igennem og erstatte css-klassen med `bibgraphEnabled` eller `bibgraphDisabled` afhængigt af om der er statistik nok til en visualisering ud fra det pågældende faustnummer. Klik på det pågældende element, vil da få visualiseringen til at poppe op.

Se `public/style.css` i dette repositorie for eksempel på hvorledes det kunne styles.

# Overblik over filer

- `adhl.json` behandlet og anonymiseret udtræk fra ADHL-databasen, - et json-objekt per linje, enten `["faust", "$FAUSTNUMMER", "$KLYNGEID"]` for mapning mellem faustnumre og klynger, eller `["adhl", "$KLYNGEID", [["$KLYNGEID", "$COUNT"], ["$KLYNGEID2", "$COUNT2"], ["$KLYNGEID3", "$COUNT3"], ...]]` der lister antal co-lån for de hyppigst lånte klynger, hvor det første `$COUNT` er antal lån for selve klyngen. 
- `importdata.py` laver `adhl.leveldb`, som er en komprimeret database af json-objekter genereret fra `adhl.json`
- `updateData.coffee` opdaterer data i `adhl.leveldb`, således at der er information til at lave andre statistiske vægtninger end `P(A|B)`
- `server.coffee` webserver på port 1234, der eksponerer public-kataloget, samt et par simple json webservices.
- `public/client.[coffee|js]` selve visualiseringskoden

# API

- `bibgraph.update()` finder elementer i DOMen der har css-klassen `bibgraphRequest`, ændre klasse på dem, og gør dem klikbare hvis deres `data-faust` attribut er et faustnummer som der er ADHL-data på. Kaldes automatisk, men er også eksponeres, så den kan kaldes hvis DOMen opdateres (eksempelvis ved dynamisk indlæsning af søgeresultat.
- `bibgraph.open(klyngeId, pos)` - åbn visualisering for en enkelt klynge, placer det på skærmen, (pos er et json-objekt, med `x`,`y`-properties)
- `bibgraph.close()` - luk igangværende visualisering
- `bibgraph.boxContent(elem, faust)` funktion der putter indhold i det html-element der repræsenterer et fasutnummer i grafen, - loader titel asynkront, og opdaterer elementet. Funktionen kan erstattes med custom javascript, hvis man vil tilpasse indholdet af de visualiserede materialer.

# Progress

## To do

- disable for ie8 and older (works with ie9+)
- encode expansions+fixedPoss in hash if not used for anything else
- open selected in bibliotek.dk
- touch-events bugfix
- bundle, such that embedding wont need depencies such as d3. Ie. should be possible to add the functionality to a site by just including a single js + customise style.
- remove debug/qp.log logging code

## Done
- better landing/info-page
    - bibdk search box
    - examples
    - layout via bootstrap
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

- move div, in addition to update graph coordinates
- pinned initial book


# REST API

- `http://localhost:1234/faust/$FAUST_ID` 
- `http://localhost:1234//klynge/$KLYNGE_ID`
- `http://localhost:1234//search/$QUERY`

# Database

Uses a single leveldb of json objects. LevelDB is used as it is simple to run key-value-store, which has compression to mitigate the cost of having data encoded as json.

- `faust:####` mapping from faustnumber to klynge + optional title
- `klynge:###` data about each klynge

# License

Copyright 2013 DBC A/S <http://dbc.dk>

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 2 of the License, or
(at your option) any later version.
