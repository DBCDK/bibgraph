klynger = []

$graph = undefined

update = ->
  $graph.empty()
  klynger = klynger.filter (klynge) -> klynge.adhl
  for klynge in klynger
    $graph.append "<div>#{klynge.title} #{klynge.adhl[0][1]}</div>"

requestKlynge = (klynge) ->
  $.get "klynge/" + klynge, (klynge) ->
    klynger.push klynge
    $.get "faust/" + klynge.faust[0], (faust) ->
      klynge.title = faust.title
      update()
      console.log klynge

search = () ->
  query = ($ "#query")
    .css({display: "none"})
    .val()
  klynger = []
  qp.log "search", query
  $.get "search/" + query, (result) ->
    ($ "#query")
      .css({display: "inline"})
      .val("")
    result.map (faust) ->
      $.get "faust/" + faust, (faust) ->
        requestKlynge faust?.klynge if faust?.klynge

$ ->
  $graph = $ "#graph"
  ($ "#search").on "submit", ->
    search()
    false
  if location.hash
    ($ "#query").val location.hash.slice(1)
    search()
