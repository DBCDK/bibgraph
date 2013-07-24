# Graph management {{{1
klynger = []

reset = ->
  window.klynger = klynger = []

start = ->
  expand() if klynger.length
  update()


expand = ->
  return if klynger.length > 4
  for i in [0..10]
    klynge = klynger[Math.random()*klynger.length | 0]
    for child in klynge.adhl
      if !existing[child.klynge]
        console.log existing, child.klynge
        return requestKlynge child.klynge, expand

expand = ->
  return if klynger.length > 4

  existing = {}
  for klynge in klynger
    existing[klynge.klynge] = true

  klynge = klynger[Math.random()*klynger.length | 0]
  for child in klynge.adhl
    if !existing[child.klynge]
      console.log "found", existing, child, JSON.stringify klynger.map (k) -> k.klynge
      return requestKlynge child.klynge, expand

# Add a klynge to the klynge-list, loading it from the api {{{2
requestKlynge = (klyngeId, done) ->
  $.get "klynge/" + klyngeId, (klynge) ->
    console.log klyngeId, klynge
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

      # Discard all but the most popular result
      , ->
        max = {count: 0}
        for klynge in klynger
          if max.count <= klynge.count
            max = klynge
        klynger = [max]
        console.log "root:", max
        start()


# Handle seach request and location.hash {{{1
$ ->
  ($ "#search").on "submit", ->
    search()
    false
  if location.hash
    ($ "#query").val location.hash.slice(1)
    search()
