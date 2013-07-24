nNodes = 70
edgeTry = 6
klynger = []

# Draw graph {{{1
#
draw = ->
  klynger = klynger.reverse()
  w = window.innerWidth
  h = window.innerHeight
  force = d3.layout.force() #{{{2

  document.getElementById("graph").innerHTML = ""
  svg = d3.select("#graph").append("svg")
  svg.attr("width", w)
  svg.attr("height", h)


  for i in [0..klynger.length - 1] #{{{2
    klynger[i].index = i

  for klynge in klynger
    klynge.label = klynge.title.replace("&amp;", "&").replace /&#([0-9]*);/g, (_, n) -> String.fromCharCode n

  idx = {}
  idx[klynge.klynge] = klynge.index for klynge in klynger

  edges = []
  for a in klynger
    for b in a.adhl.slice(0, edgeTry)
      if typeof idx[b.klynge] == "number"
        edges.push
          source: a.index
          target: idx[b.klynge]


  link = svg #{{{2
            .selectAll(".link")
            .data(edges)
            .enter()
            .append("line")
            .attr("class", "link")
            .style("stroke", "#999")
            .style("stroke-width", 1)

  node = svg #{{{2
            .selectAll(".node")
            .data(klynger)
            .enter()
            .append("text")
            .style("font", "12px sans-serif")
            .style("text-anchor", "middle")
            .style("text-shadow", "1px 1px 0px white, -1px -1px 0px white, 1px -1px 0px white, -1px 1px 0px white")
            .attr("class", "node")
            .call(force.drag)

  updateForce = -> #{{{2
            link.attr("x1", (d) -> d.source.x)
                .attr("y1", (d) -> d.source.y)
                .attr("x2", (d) -> d.target.x)
                .attr("y2", (d) -> d.target.y)

            node
                .attr("x", (d) -> d.x)
                .attr("y", (d) -> d.y + 2)
                .text((d) -> d.label or d._id)


  force.size [w, h]
  force.on "tick", -> updateForce()
  force.nodes klynger
  force.links edges
  force.charge -120
  force.linkDistance 100
  force.linkStrength 0.3
  force.gravity 0.1
  force.start()



# Graph management {{{1

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
  return done?() if klynger.length >= nNodes

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
        return start ->
          draw()

        klynger = klynger.slice 0, 1
        return start ->
          draw()

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
  ($ "#search").focus()
