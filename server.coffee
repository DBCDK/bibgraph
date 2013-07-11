# API {{{1

levelup = require "levelup"
db = levelup __dirname + "/adhl.leveldb", {createIfMissing: false}

faust = (id, cb) ->
  db.get "faust:" + id, (err, json) ->
    return cb err if err
    json = JSON.parse json
    return cb err, json if json.title
    bibdkTitle id, (err, title) ->
      return cb err if err
      json.title = title
      cb err, json
      db.put "faust:" + id, JSON.stringify json

klynge = (id, cb) ->
  db.get "klynge:" + id, (err, data) -> cb err, JSON.parse data

search = (query, cb) ->
  db.get "search:" + query, (err, result) ->
    return cb err, JSON.parse result if not err
    bibdkSearch query, (err, result) ->
      cb err, result
      db.put "search:" + query, JSON.stringify result

# Scrape bibliotek.dk {{{1
request = require "request"
bibdkTitle = (faust, cb) ->
  request "http://bibliotek.dk/vis.php?term1=lid%3D" + faust, (err, res, body) ->
    return cb err if err
    re = /<span id="linkSign-item1"[^<]*<.span..nbsp.([^<]*)/
    cb err, (body.match re)[1]

resultCount = 5
bibdkSearch = (query, cb) ->
  request "http://bibliotek.dk/vis.php?term1=#{query}&step=#{resultCount}", (err, res, body) ->
    return cb err if err
    uniq = {}
    body.replace /permalink_([^_]*)/g, (_, faust) -> uniq[faust] = true
    cb err, Object.keys uniq

# HTTP Server {{{1
express = require "express"
app = express()

jsonp = (fn) -> (req, res) ->
    fn req.params.val, (err, result) ->
      if err then res.end "" + err else res.jsonp result

app.all "/faust/:val", jsonp faust
app.all "/klynge/:val", jsonp klynge
app.all "/search/:val", jsonp search
app.use "/", express.static "public"

app.listen "1234"
console.log "listening on localhost:1234"
