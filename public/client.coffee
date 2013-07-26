nNodes = 100
edgeTry = 20
klynger = []
divWidth = 60

# Util to be merged into qp{{{1

qp = window.qp || {}
qp.prngSeed = Date.now()
qp.prng = (n) -> qp.prngSeed = (1664525 * (if n == undefined then qp.prngSeed else n) + 1013904223) |0
qp.strhash = (s) ->
  hash = 5381
  i = s.length
  while i
    hash = (hash*31 + s.charCodeAt(--i)) | 0 
  hash
qp.intToColor = (i) -> "#" + ((i & 0xffffff) + 0x1000000).toString(16).slice(1)
qp.hashColorLight = (s) -> qp.intToColor 0xe0e0e0 | qp.prng 1 + qp.strhash s
qp.hashColorDark = (s) -> qp.intToColor 0x7f7f7f & qp.prng qp.strhash s

# PopUp Menu {{{1

movingKlynge = undefined
movingX = 0
movingY = 0
movingX0 = 0
movingY0 = 0

addMenu = ($elem, klynge) ->
  elem = $elem[0]
  # TODO functions below should not be defined in the closure
  elem.addEventListener "mousedown", (e) ->
    return if movingKlynge
    e.preventDefault()
    movingKlynge = klynge
    movingX0 = movingX = e.x
    movingY0 = movingY = e.y
    klynge.fixed = true
    showMenuItems()
    true

stopMoving  = (e) ->
  e.preventDefault()
  movingKlynge.fixed = movingKlynge.pinned if movingKlynge
  movingKlynge = undefined
  true
movingMouseMove = (e) ->
    return if not movingKlynge
    klynge = movingKlynge
    e.preventDefault()
    dx = e.x - movingX
    dy = e.y - movingY
    klynge.x += dx
    klynge.y += dy
    klynge.px += dx
    klynge.py += dy
    movingX += dx
    movingY += dy
    console.log klynge.x, klynge.px, movingX
    force.start()
    true

$ ->
  window.addEventListener "mousemove", movingMouseMove
  window.addEventListener "mouseup", stopMoving
  window.addEventListener "mouseleave", stopMoving


# Draw graph {{{1
#
draw = ->
  klynger = klynger.reverse()
  w = window.innerWidth
  h = window.innerHeight
  window.force = force = d3.layout.force() #{{{2

  document.getElementById("graph").innerHTML = ""
  svg = d3.select("#graph").append("svg")
  svg.attr("width", w)
  svg.attr("height", h)


  for i in [0..klynger.length - 1] #{{{2
    klynger[i].index = i

  for klynge in klynger
    klynge.label = String(klynge.title).replace("&amp;", "&").replace /&#([0-9]*);/g, (_, n) -> String.fromCharCode n
    klynge.label = ""

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

  for klynge in klynger
    klynge.title = "" + klynge.title
    $div = $ "<div>" + klynge.title + "</div>"
    $div.data "klynge", klynge
    $div.css
      position: "absolute"
      width: divWidth
      font: "100px sans serif"
      textAlign: "center"
      #border: "1px solid rgba(0,0,0,0.3)"
      color: qp.hashColorDark klynge.title
      background: qp.hashColorLight klynge.title
      hyphens: "auto"
      MozHyphens: "auto"
      WebkitHyphens: "auto"
      overflow: "hidden"
      boxShadow: "3px 3px 8px rgba(0, 0, 0, 0.5)"
      padding: 4
      borderRadius: 4
    $("body").append $div
    size = 12
    addMenu $div, klynge
    while $div.height() > divWidth and size > 8
      --size
      $div.css {fontSize: size}
    $div.css {height: divWidth}
    klynge.div = $div[0]

  n = 0
  updateForce = -> #{{{2
    for klynge in klynger
      klynge.div.style.top = klynge.y + "px"
      klynge.div.style.left = (klynge.x - divWidth/2) + "px"
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
  force.charge -400
  force.linkDistance 120
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

_pickN = 1
pick = (arr) ->
  _pickN = qp.prng _pickN
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
    klynge.adhl?.sort (a, b) ->
      b.count*b.count/b.klyngeCount - a.count*a.count/a.klyngeCount
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
