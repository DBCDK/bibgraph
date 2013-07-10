addKlynge = (klynge) ->
  console.log klynge

search = () ->
  query = ($ "#query")
    .css({display: "none"})
    .val()
  qp.log "search", query
  $.get "search/" + query, (result) ->
    ($ "#query")
      .css({display: "inline"})
      .val("")
    result.map (faust) ->
      $.get "faust/" + faust, (faust) ->
        if faust?.klynge
          $.get "klynge/" + faust?.klynge, (klynge) ->
            klynge.title = faust.title
            addKlynge klynge

$ ->
  ($ "#search").on "submit", ->
    search()
    false
