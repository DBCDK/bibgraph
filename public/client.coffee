nNodes = 100
edgeTry = 10
boxSize = 60

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
qp.log = (args...) -> qp._log? document.title, args...

# Drag and popUp Menu {{{1
# State {{{2
movingKlynge = undefined
movingX = 0
movingY = 0
movingX0 = 0
movingY0 = 0

addMenu = ($elem, klynge) -> #{{{2
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

stopMoving  = (e) -> #{{{2
  e.preventDefault()
  movingKlynge.fixed = movingKlynge.pinned if movingKlynge
  movingKlynge = undefined
  true

movingMouseMove = (e) -> #{{{2
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
  force.start()
  true

$ -> # Bind events {{{2
  window.addEventListener "mousemove", movingMouseMove
  window.addEventListener "mouseup", stopMoving
  window.addEventListener "mouseleave", stopMoving

# Draw graph {{{1
#
ctx = undefined
canvas = undefined
klynger = []
edges = []
force = undefined
findEdges = -> #{{{2
  for i in [0..klynger.length - 1]
    klynger[i].index = i

  idx = {}
  idx[klynge.klynge] = klynge.index for klynge in klynger

  edges = []
  for a in klynger
    for b in a.adhl.slice(0, edgeTry)
      if typeof idx[b.klynge] == "number"
        edges.push
          source: a.index
          target: idx[b.klynge]

startDrawing = -> #{{{2
  initDraw()
  findEdges()
  draw()

initDraw = -> #{{{2

  document.getElementById("graph").innerHTML = ""
  $canvas = $ "<canvas></canvas>"
  $("#graph").append $canvas
  canvas = $canvas[0]
  ctx = canvas.getContext "2d"
  $canvas.css
    position: "absolute"
    top: 0
    left: 0

  window.force = force = d3.layout.force() 
  force.size [window.innerWidth, window.innerHeight]
  force.on "tick", forceTick
  force.charge -400
  force.linkDistance 150
  force.linkStrength 0.3
  force.gravity 0.1

draw = -> #{{{2
  # Resize canvas {{{3
  w = window.innerWidth
  h = window.innerHeight
  ctx.width = canvas.width = w
  ctx.height = canvas.height = h
  canvas.style.width = w + "px"
  canvas.style.heiht = h + "px"


  # Generate titles for klynger {{{3
  for klynge in klynger
    klynge.label = String(klynge.title).replace("&amp;", "&").replace /&#([0-9]*);/g, (_, n) -> String.fromCharCode n
    klynge.label = ""

  # Create divs for klynger {{{3
  for klynge in klynger.reverse()
    klynge.title = "" + klynge.title
    $div = $ "<div>" + klynge.title + "</div>"
    $div.data "klynge", klynge
    $div.css
      position: "absolute"
      width: boxSize
      font: "100px sans serif"
      textAlign: "center"
      #border: "1px solid rgba(0,0,0,0.3)"
      color: qp.hashColorDark klynge.title
      background: qp.hashColorLight klynge.title
      background: "rgba(255,255,255,0.75)"
      hyphens: "auto"
      MozHyphens: "auto"
      WebkitHyphens: "auto"
      overflow: "hidden"
      boxShadow: "1px 1px 4px rgba(0, 0, 0, 0.5)"
      padding: 4
      borderRadius: 4
    $("#graph").append $div

    # Scale font to fit each box {{{3
    size = 12
    addMenu $div, klynge
    while $div.height() > boxSize and size > 8
      --size
      $div.css {fontSize: size}
    $div.css {height: boxSize}
    klynge.div = $div[0]

  # Update force graph {{{3
  force.nodes klynger
  force.links edges
  force.start()

forceTick = -> #{{{2
  for klynge in klynger
    klynge.div.style.top = (klynge.y - boxSize/2) + "px"
    klynge.div.style.left = (klynge.x - boxSize/2) + "px"

  ctx.lineWidth = 0.3
  ctx.clearRect 0, 0, canvas.width, canvas.height
  ctx.beginPath()
  for edge in edges
    ctx.moveTo edge.source.x, edge.source.y
    ctx.lineTo edge.target.x, edge.target.y
  ctx.stroke()


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

# Main - to be replaced with better embedding when going public {{{1

# Search {{{2
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
      , ->
        max = {count: 0}
        for klynge in klynger
          if max.count <= klynge.count
            max = klynge
        klynger = [max]
        console.log "root:", max
        start ->
          startDrawing()
          console.log "done"


# Handle seach request and location.hash {{{2
$ ->
  ($ "#search").on "submit", ->
    search()
    false
  if location.hash
    ($ "#query").val location.hash.slice(1)
    search()
  ($ "#search").focus()
