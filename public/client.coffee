addKlynge = (klynge) ->
  console.log klynge

search = (query) ->
  $.get "search/" + query, (result) ->
    result.map (faust) ->
      $.get "faust/" + faust, (faust) ->
        if faust?.klynge
          $.get "klynge/" + faust?.klynge, (klynge) ->
            klynge.title = faust.title
            addKlynge klynge

$ ->
  ($ "#search").on "touchstart mousedown", ->
    search ($ "#query").val()
