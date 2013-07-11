# Graph management {{{1
klynger = []

reset = -> undefined
start = -> undefined

# Add a klynge to the klynge-list, loading it from the api {{{2
requestKlynge = (klynge, done) ->
  $.get "klynge/" + klynge, (klynge) ->
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
    $graph.append "<div>#{klynge.title} #{klynge.adhl[0][1]}</div>"

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
        max = {adhl:[[0,0]]}
        for klynge in klynger
          if max.adhl[0][1] <= klynge.adhl[0][1]
            max = klynge
        klynger = [max]
        update()


# Handle seach request and location.hash {{{1
$ ->
  ($ "#search").on "submit", ->
    search()
    false
  if location.hash
    ($ "#query").val location.hash.slice(1)
    search()
