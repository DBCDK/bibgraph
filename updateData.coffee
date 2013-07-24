levelup = require "levelup"
async = require "async"

db = levelup __dirname + "/adhl.leveldb", {createIfMissing: false}

addKlyngeCount = (done) ->
  count = 0
  stream = db.createReadStream
      start: "klynge:"
      end: "klyngf"
  
  stream.on "data", (data) ->
    key = data.key
    val = JSON.parse data.value
    if val.adhl and ! val.count
      stream.pause()
      val.klynge = val.adhl[0][0]
      val.count = val.adhl[0][1]
      val.adhl = val.adhl.slice(1)
      db.put key, JSON.stringify(val), (err)->
        throw err if err
        stream.resume()
  
    ++count
    console.log "adding metadata", count if count % 1000 == 0
  stream.on "end", ->
    done?()

addAdhlMeta = (done) ->
  count = 0
  stream = db.createReadStream
      start: "klynge:"
      end: "klyngf"
  
  stream.on "data", (data) ->
    key = data.key
    val = JSON.parse data.value
    if val.adhl and Array.isArray val.adhl[0]
      stream.pause()
      async.map(val.adhl,
        (elem, done) ->
          db.get "klynge:" + elem[0], (err, data) ->
            data = JSON.parse data if data
            done null,
              count: elem[1]
              klynge: elem[0]
              klyngeCount: data?.count || undefined,
        (err, results)->
          throw err if err
          val.adhl = results
          db.put key, JSON.stringify(val), (err)->
            throw err if err
            stream.resume())
  
    ++count
    console.log "enriching adhl", count if count % 1000 == 0
  stream.on "end", ->
    done?()

addKlyngeCount addAdhlMeta
