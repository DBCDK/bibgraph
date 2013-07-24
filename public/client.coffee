# Graph management {{{1
klynger = []

reset = ->
  existing = {}
  _pickN = 0
  window.klynger = klynger = []

start = (done)->
  expand done if klynger.length
  update()

prng = (n) -> (1664525*n + 1013904223) |0

_pickN = 0
pick = (arr) ->
  _pickN = prng _pickN
  arr[(_pickN&0x7fffffff) % arr.length]


existing = {}
expand = (done) ->
  return done?() if klynger.length >= 100

  for klynge in klynger
    existing[klynge.klynge] = true

  for i in [0..20]
    klynge = klynger[Math.random()*klynger.length | 0]
    klynge = pick klynger
    for child in klynge.adhl
      if !existing[child.klynge]
        existing[child.klynge] = true
        return requestKlynge child.klynge, ->
          expand done

# Add a klynge to the klynge-list, loading it from the api {{{2
requestKlynge = (klyngeId, done) ->
  $.get "klynge/" + klyngeId, (klynge) ->
    return done?() if not klynge.faust
    klynger.push klynge
    $.get "faust/" + klynge.faust[0], (faust) ->
      klynge.title = faust.title
      update()
      done?()


# Update the view on graph change
$graph = undefined
$ -> $graph = $ "#graph"

update = ->
  $graph.empty()
  klynger = klynger.filter (klynge) -> klynge.adhl
  for klynge in klynger
    $graph.append "<span> &nbsp; #{klynge.title} #{klynge.count}</span>"

# Search {{{1
search = () ->
  reset()
  query = ($ "#query")
    .css({display: "none"})
    .val()
  location.hash = query
  klynger = []
  qp.log "search", query

  # Send search query to web service
  $.get "search/" + query, (result) ->
    ($ "#query")
      .css({display: "inline"})
      .val("")

    # Lookup each of the result
    async.map result, (faust, done) ->
        $.get "faust/" + faust, (faust) ->
          if faust?.klynge
            requestKlynge faust?.klynge, done
          else
            done()

      # ÷÷÷÷Discard all but the most popular result
      # ÷÷÷÷Discard all but first result
      , ->
        klynger = klynger.slice 0, 1
        return start ->
          console.log "done"

        max = {count: 0}
        for klynge in klynger
          if max.count <= klynge.count
            max = klynge
        klynger = [max]
        console.log "root:", max
        start ->
          console.log "done"


# Handle seach request and location.hash {{{1
$ ->
  ($ "#search").on "submit", ->
    search()
    false
  if location.hash
    ($ "#query").val location.hash.slice(1)
    search()
