# ![logo](https://solsort.com/_logo.png) BibGraph visualisation

Visualisations of related books, based on the ADHL-data

Work in progress

# Internal details

## REST API

- `/faust/$FAUST_ID` 
- `/klynge/$KLYNGE_ID`
- `/search/$QUERY`

## Database

Uses a single leveldb

- `faust:####` mapping from faustnumber to klynge + optional title
- `klynge:###` data about each klynge
