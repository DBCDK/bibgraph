boxSize = 60
boxPadding = 4
walkDepth = 30
startSpread = 4
topLinks = 5

klynger = {}
nodes = []
links = []
pinned = {}

window.bibgraph = {}

# Util to be merged into qp{{{1

qp = window.qp = window.qp || {}
qp.prngSeed = Date.now()
qp.prng = (n) -> qp.prngSeed = (1664525 * (if n == undefined then qp.prngSeed else n) + 1013904223) |0
qp.prng01 = -> (qp.prng() & 0x0fffffff) / 0x10000000
qp.strHash = (s) ->
  hash = 5381
  i = s.length
  while i
    hash = (hash*31 + s.charCodeAt(--i)) | 0 
  hash
qp.intToColor = (i) -> "#" + ((i & 0xffffff) + 0x1000000).toString(16).slice(1)
qp.hashColorLight = (s) -> qp.intToColor 0xe0e0e0 | qp.prng 1 + qp.strHash s
qp.hashColorDark = (s) -> qp.intToColor 0x7f7f7f & qp.prng qp.strHash s
qp.log = (args...) -> qp._log? document.title, args...
qp.pick = (arr, seed) -> arr[Math.abs(qp.prng(seed)) % arr.length]
qp.startsWith = (str, match) -> str.slice(0, match.length) == match

# Entry/exit point {{{1

bibgraph.open = (klyngeId) -> #{{{2
  console.log location.hash, location.hash == ""
  if (location.hash == "") or (qp.startsWith location.hash, "#bibgraph:")
    location.hash = "#bibgraph:" + klyngeId
  initDraw()
  pinned[klyngeId] = true
  update()

bibgraph.close = (klyngeId) -> #{{{2
  $("#bibgraphGraph").remove()
  for _, klynge of klynger
    klynge.div = undefined 
  nodes = []
  links = []
  pinned = {}

# Handle mouse/touch {{{1

wasPinned = px0 = py0 = x0 = y0 = startTime = $touched = touchedKlynge = undefined

doStart = (e, $elem, klynge, x, y) ->
  return if $touched
  touchedKlynge = klynge
  px0 = touchedKlynge.px
  py0 = touchedKlynge.py
  $touched = $elem
  x0 = x
  y0 = y
  startTime = Date.now()

  $touched.addClass "pinned"
  wasPinned = pinned[touchedKlynge.klynge]
  pinned[touchedKlynge.klynge] = true
  touchedKlynge.fixed = true
  update() if !wasPinned

  e.preventDefault()
  true

doMove = (e, x, y) ->
  return if !$touched

  touchedKlynge.px = px0 + x - x0
  touchedKlynge.py = py0 + y - y0
  force.start()

  e.preventDefault()
  true

doEnd = (e, x, y) ->
  return if !$touched

  dx = x - x0
  dy = y - y0
  dist = Math.sqrt(dx*dx + dy*dy)

  if wasPinned and dist < boxSize and (startTime + 500) > Date.now()
    pinned[touchedKlynge.klynge] = false
    touchedKlynge.fixed = false
    $touched.removeClass "pinned"
    update()

  $touched = undefined

  e.preventDefault()
  true

handleMove = ($elem) ->
  $elem.on "mouseup", (e) -> doEnd e, e.screenX, e.screenY
  $elem.on "mousemove", (e) -> doMove e, e.screenX, e.screenY
handleTouch = ($elem, klynge) ->
  handleMove $elem
  $elem.on "mousedown", (e) -> doStart e, $elem, klynge, e.screenX, e.screenY

# Draw graph {{{1
#
ctx = undefined
canvas = undefined
force = undefined

initDraw = -> #{{{2

  force = d3.layout.force()
  force.size [window.innerWidth, window.innerHeight]
  force.on "tick", forceTick
  force.charge -400
  force.linkDistance 150
  force.linkStrength 0.3
  force.gravity 0.1

  ($ "body").append $ '<div id="bibgraphGraph"></div>' if !($ "#bibgraphGraph").length
  $("#bibgraphGraph").empty()
  $canvas = $ "<canvas></canvas>"
  $("#bibgraphGraph").append $canvas
  canvas = $canvas[0]
  ctx = canvas.getContext "2d"
  $canvas.css
    position: "absolute"
    top: 0
    left: 0


  setTimeout (->
    $canvas.on "click", (e) -> bibgraph.close()
    handleMove $canvas), 500

  # Resize canvas {{{3
  w = window.innerWidth
  h = window.innerHeight
  ctx.width = canvas.width = w
  ctx.height = canvas.height = h
  canvas.style.width = w + "px"
  canvas.style.heiht = h + "px"


draw = -> #{{{2

  # Create divs for nodes {{{3
  for klynge in nodes
    if not klynge.div
      $div = $ "<div></div>"
      $div.addClass "bibgraphBox"
      $div.addClass "pinned" if pinned[klynge.klynge]
      $div.data "klynge", klynge
      $div.css
        width: boxSize - 2*boxPadding
        padding: boxPadding
        borderRadius: boxPadding
        height: boxSize - 2*boxPadding
      handleTouch $div, klynge
      $("#bibgraphGraph").append $div
      bibgraph.boxContent $div[0], klynge.faust
      klynge.div = $div[0]

  # Update force graph {{{3
  force.nodes nodes
  force.links links
  force.start()

forceTick = -> #{{{2
  for klynge in nodes
    if klynge.div
      klynge.div.style.top = klynge.y + "px"
      klynge.div.style.left = klynge.x + "px"

  ctx.lineWidth = 0.3
  ctx.clearRect 0, 0, canvas.width, canvas.height
  ctx.beginPath()
  for link in links
    if link.source.div and link.target.div
      ctx.moveTo link.source.x + boxSize / 2, link.source.y + boxSize / 2
      ctx.lineTo link.target.x + boxSize / 2, link.target.y + boxSize / 2
  ctx.stroke()

# Graph management {{{1
graphLoading = false
klyngeWalk = (klyngeId, n, callback, done, acc) -> #{{{2

  return done() if n <= 0
  acc ?= {arr:[], added:{}, salt: (qp.strHash klyngeId), skip: {}, startSpread: startSpread}

  loadKlynge klyngeId, (klynge) ->
    if klynge.klynge
      acc.arr.push klynge
      acc.added[klyngeId] = true
      klynge.children ?= {}
    else
      acc.skip[klyngeId] = true

    hash = acc.salt + qp.strHash klyngeId
    for i in [0..30]
      branch = qp.pick acc.arr, hash
      if acc.startSpread > 0
        branch = acc.arr[0]
        acc.startSpread--

      p = qp.prng01()
      p *= p
      p *= p
      p *= p
      pos = p * branch.adhl.length | 0
      console.log pos
      if branch.adhl then for child in branch.adhl.slice(pos)
        if !acc.added[child.klynge] and !acc.skip[child.klynge]
          branch.children[child.klynge] = true
          acc.prev = branch.klynge
          if klynge.klynge
            callback klynge
          return klyngeWalk child.klynge, n - 1, callback, done, acc
      hash = qp.prng hash
    callback klynge

loadKlynge = (klyngeId, callback)  -> #{{{2
  if klynger[klyngeId]
    return callback klynger[klyngeId]

  $.get "klynge/" + klyngeId, (klynge) ->

    klynge = {raw: klynge} if typeof klynge != "object"
    klynger[klyngeId] = klynge

    klynge.adhl?.sort (a, b) ->
      b.count*b.count/b.klyngeCount - a.count*a.count/a.klyngeCount
    updateKlynge klynge if klynge.faust

    callback klynge

updateKlynge = (klynge) -> #{{{2
  $.get "faust/" + klynge.faust[0], (faust) ->
    klynge.title = faust.title
    draw()

update = -> #{{{2
  nodes = []
  links = []
  nodeHash = {}
  linkHash = {}

  addLink = (a, b) -> #{{{3
    [a, b] = [b, a] if a > b
    return if !nodeHash[a] or !nodeHash[b] or linkHash[[a,b]]
    linkHash[[a,b]] = true
    links.push
      source: nodeHash[a]
      target: nodeHash[b]



  handleResult = (klynge) -> #{{{3
    id = klynge.klynge
    return if !id
    if !nodeHash[id]
      nodeHash[id] = klynge
      nodes.push klynge
      for child in klynge.adhl.slice(0,topLinks)
        klynge.children[child.klynge] = true
        addLink id, child.klynge
    for klynge in nodes
      if klynge.children[id]
        addLink klynge.klynge, id
    draw()

  done = () -> #{{{3
    for klynge in nodes
      for child in klynge.children
        addLink klynge.klynge, child
    draw()

    for _, klynge of klynger
      if klynge.div and !nodeHash[klynge.klynge]
        ($ klynge.div).remove()
        klynge.div = undefined

  toWalk = [] #{{{3
  for klyngeId, isPinned of pinned
    if isPinned
      toWalk.push klyngeId

  return bibgraph.close() if !toWalk.length
  depth = walkDepth / Math.log (toWalk.length + 1.7)
  console.log depth

  async.map toWalk, ((id, done) -> klyngeWalk id, depth, handleResult, done), done

# Runner {{{1
# new {{{2
titleCache = {} #{{{2
bibgraph.boxContent = (elem, fausts) ->
  faust = fausts[0]
  title = titleCache[faust]
  elem.innerHTML = "?"
  elem.style.color = qp.hashColorDark faust
  if title != undefined
    return elem.innerHTML = "<span>#{title}</span>"

  $.get ("faust/" + faust), (obj) ->
    title = obj.title
    titleCache[faust] = title
    elem.innerHTML = "<span>#{title}</span>"

  
    # Scale font to fit each box {{{3
    $div = $ elem
    size = 12
    while $div.height() > boxSize and size > 8
      --size
      $div.css {fontSize: size}
    $div.css {height: boxSize}

bibgraph.update = -> #{{{2
  ($ ".bibgraphRequest").each ->
    $elem = $ this

    if ! $elem.hasClass "bibgraphRequestLoading"
      $elem.addClass "bibgraphRequestLoading"
      $.get ("faust/" + $elem.data "faust"), (faust) ->
        $.get ("klynge/" + faust.klynge), (klynge) ->
          $elem.removeClass "bibgraphRequestLoading"
          $elem.removeClass "bibgraphRequest"
          if klynge?.adhl
            $elem.addClass "bibgraphEnabled"
            $elem.on "mousedown", -> bibgraph.open faust.klynge
            $elem.on "touchstart", -> bibgraph.open faust.klynge
          else
            $elem.addClass "bibgraphDisabled"

$ bibgraph.update #{{{2
