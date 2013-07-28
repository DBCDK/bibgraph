boxSize = 60
boxPadding = 4
walkDepth = 80

klynger = {}
nodes = []
links = []
pinned = {}

# Util to be merged into qp{{{1

qp = window.qp = window.qp || {}
qp.prngSeed = Date.now()
qp.prng = (n) -> qp.prngSeed = (1664525 * (if n == undefined then qp.prngSeed else n) + 1013904223) |0
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

# Handle mouse/touch {{{1

wasPinned = px0 = py0 = x0 = y0 = startTime = $touched = touchedKlynge = undefined

doStart = (e, $elem, klynge, x, y) ->
  console.log "start", $touched
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

  e.preventDefault()
  true

doMove = (e, x, y) ->
  console.log "move", $touched
  return if !$touched

  touchedKlynge.px = px0 + x - x0
  touchedKlynge.py = py0 + y - y0
  force.start()

  e.preventDefault()
  true

doEnd = (e, x, y) ->
  console.log "end", $touched
  return if !$touched

  dx = x - x0
  dy = y - y0
  dist = Math.sqrt(dx*dx + dy*dy)

  console.log dist, boxSize, startTime, Date.now()

  if wasPinned and dist < boxSize and (startTime + 500) > Date.now()
    pinned[touchedKlynge.klynge] = false
    touchedKlynge.fixed = false
    $touched.removeClass "pinned"

  $touched = undefined

  e.preventDefault()
  true

handleTouch = ($elem, klynge) ->
  $elem.on "mousedown", (e) -> doStart e, $elem, klynge, e.screenX, e.screenY

$ ->
  ($ window).on "mouseup", (e) -> doEnd e, e.screenX, e.screenY
  ($ window).on "mousemove", (e) -> doMove e, e.screenX, e.screenY

# Draw graph {{{1
#
ctx = undefined
canvas = undefined
force = undefined

initDraw = -> #{{{2

  window.force = force = d3.layout.force()
  force.size [window.innerWidth, window.innerHeight]
  force.on "tick", forceTick
  force.charge -400
  force.linkDistance 150
  force.linkStrength 0.3
  force.gravity 0.1

  document.getElementById("graph").innerHTML = ""
  $canvas = $ "<canvas></canvas>"
  $("#graph").append $canvas
  canvas = $canvas[0]
  ctx = canvas.getContext "2d"
  $canvas.css
    position: "absolute"
    top: 0
    left: 0

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
    if klynge.title and not klynge.div
      klynge.title = "" + klynge.title
      $div = $ "<div>" + klynge.title + "</div>"
      $div.addClass "bibgraphBox"
      $div.addClass "pinned" if pinned[klynge.klynge]
      $div.data "klynge", klynge
      $div.css
        width: boxSize - 2*boxPadding
        color: qp.hashColorDark klynge.title
        padding: boxPadding
        borderRadius: boxPadding
      $("#graph").append $div

  
      # Scale font to fit each box {{{3
      size = 12
      handleTouch $div, klynge
      while $div.height() > boxSize and size > 8
        --size
        $div.css {fontSize: size}
      $div.css {height: boxSize}
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
salt = 1
klyngeWalk = (klyngeId, n, callback, done, salt, acc) -> #{{{2

  if !acc
    acc = {arr:[], added:{}, links: []} 

  if !done
    done = callback
    callback = (->)

  if typeof salt != "number"
    salt = qp.strHash klyngeId


  callback acc.arr, acc.links
  if n <= 0
    return done acc.arr, acc.links


  loadKlynge klyngeId, (klynge) ->
    acc.arr.push klynge
    acc.added[klyngeId] = true
    hash = salt + qp.strHash klyngeId
    for i in [0..30]
      branch = qp.pick acc.arr, hash
      klyngeId = branch.klynge
      if branch.adhl then for child in branch.adhl
        if !acc.added[child.klynge]
          console.log klyngeId, child.klynge, acc.added
          acc.links.push [klyngeId, child.klynge]
          return klyngeWalk child.klynge, n - 1, callback, done, salt, acc
      hash = qp.prng hash
    done acc.arr, acc.links

loadKlynge = (klyngeId, callback)  -> #{{{2
  console.log "loadKlynge", klyngeId
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
  return if !klynge.faust
  $.get "faust/" + klynge.faust[0], (faust) ->
    klynge.title = faust.title
    draw()

makeLinks = (links) ->
  link.sort() for link in links
  links = links.map JSON.stringify
  linkMap = {}
  linkMap[link] = true for link in links
  links = (Object.keys linkMap).map JSON.parse
  links.filter
  result = []
  for [a, b] in links.filter ((a) -> klynger[a[0]] and klynger[a[1]])
    source: klynger[a]
    target: klynger[b]

update = -> #{{{2
  handleResult = (localNodes, localLinks) ->
    nodes = localNodes
    for node in nodes
      if node.adhl
        for child in node.adhl.slice(0, 5)
          if klynger[child.klynge]
            localLinks.push [node.klynge, child.klynge]
    links = makeLinks localLinks
    draw()
  for klyngeId, isPinned of pinned
    console.log klyngeId, isPinned
    (klyngeWalk klyngeId, walkDepth, handleResult, handleResult) if isPinned

# Runner {{{1
requestKlynge = (klyngeId) -> #{{{2
  if klynger[klyngeId]
    klynge = klynger[klyngeId]
    nodes.push klynge if !klynge.added
    klynge.added = true
    return
  return if graphLoading
  graphLoading = true
  loadKlynge klyngeId, (klynge) ->
    klynge.children = 0
    graphLoading = false
    update()

$ ->
  search = () -> #{{{2
    nodesOld = []
    requestKlyngeOld = (klyngeId, done) ->
      $.get "klynge/" + klyngeId, (klynge) ->
        return done?() if not klynge.faust
        nodesOld.push klynge
        klynge.adhl?.sort (a, b) ->
          b.count*b.count/b.klyngeCount - a.count*a.count/a.klyngeCount
        $.get "faust/" + klynge.faust[0], (faust) ->
          klynge.title = faust.title
          nodesOld = nodesOld.filter (klynge) -> klynge.adhl
          done?()
    
    query = ($ "#query")
      .css({display: "none"})
      .val()
    location.hash = query
  
    # Send search query to web service
    $.get "search/" + query, (result) ->
      ($ "#query")
        .css({display: "inline"})
        .val("")
  
      # Lookup each of the result
      async.map result, (faust, done) ->
          $.get "faust/" + faust, (faust) ->
            if faust?.klynge
              requestKlyngeOld faust?.klynge, done
            else
              done()
  
        # ÷÷÷÷Discard all but the most popular result
        , ->
          max = {count: 0}
          for klynge in nodesOld
            if max.count <= klynge.count
              max = klynge
          initDraw()
          pinned[max.klynge] = true
          update()
  
  # Handle seach request and location.hash {{{2
  
  ($ "#search").on "submit", ->
    search()
    false
  if location.hash
    ($ "#query").val location.hash.slice(1)
    search()
  ($ "#search").focus()
