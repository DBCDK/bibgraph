boxSize = 60
boxPadding = 4
menuSize = 40
backlinks = 4
recur = 60
firstBranch = 6
eachBranch = 3

klynger = {}
nodes = []
links = []
root = undefined

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

# Drag and popUp Menu {{{1
clickTime = 0
movingKlynge = undefined
movingX = 0
movingY = 0
movingX0 = 0
movingY0 = 0

# Handlers {{{2
pin = (klynge) -> #{{{3
  pinned = !klynge.pinned
  klynge.pinned = pinned
  klynge.fixed = pinned
  if pinned
    ($ klynge.div).addClass "pinned"
  else
    ($ klynge.div).removeClass "pinned"

increase = (klynge) -> #{{{3
  klynge.children += 3
  update()

decrease = (klynge) -> #{{{3
  klynge.children -= 3 if klynge.children >= 3
  update()

clear = (klynge) -> #{{{3
  klynge.children = 0
  update()

expand = (klynge) -> #{{{3
  recur = 10
  root = klynge.klynge
  klynger = {}
  klynger[root] = klynge
  klynge.children = firstBranch
  nodes = []
  initDraw()
  update()

menuItems = #{{{2
  "0":
    x: -menuSize * 1.2
    y: menuSize * .2
    fn: clear
  "-":
    x: -menuSize * .8
    y: -menuSize * .8
    fn: decrease
  "p":
    x: boxSize/2 - menuSize/2
    y: -menuSize * 1.2
    fn: pin
  "+":
    x: boxSize - menuSize * .2
    y: -menuSize * .8
    fn: increase
  "*":
    x: boxSize + menuSize * .2
    y: menuSize * .2
    fn: expand

showMenuItems = -> #{{{2
  return if !movingKlynge
  for name, item of menuItems
    ((name, item) ->
      $div = $ "<div><div>#{name}</div></div>"
      $div.addClass "bibgraphMenuItem"
      $div.css
        left: movingKlynge.x + item.x
        top: movingKlynge.y + item.y
        width: menuSize
        height: menuSize
      ($ "#graph").append $div
      $div.on "mouseup", ->
        item.fn(movingKlynge) if item.fn
        console.log "enable", name
      $div.on "mouseover", -> $div.addClass "active"
      $div.on "mouseout", -> $div.removeClass "active"
    )(name, item)

  
hideMenuItems = -> #{{{2
  $(".bibgraphMenuItem").remove()
  
addMenu = ($elem, klynge) -> #{{{2
  elem = $elem[0]
  # TODO functions below should not be defined in the closure
  elem.addEventListener "mousedown", (e) ->
    return if movingKlynge
    clickTime = Date.now()
    e.preventDefault()
    movingKlynge = klynge
    $elem.addClass "active"
    movingX0 = movingX = e.screenX
    movingY0 = movingY = e.screenY
    klynge.fixed = true
    showMenuItems()
    true

stopMoving  = (e) -> #{{{2
  e.preventDefault()
  hideMenuItems()
  return if movingKlynge == undefined
  console.log movingKlynge
  movingKlynge.fixed = movingKlynge.pinned
  ($ movingKlynge.div).removeClass "active"

  dx = movingX - movingX0
  dy = movingY - movingY0
  increase(movingKlynge) if dx*dx + dy*dy < boxSize * boxSize / 4 and Date.now() - clickTime < 300

  movingKlynge = undefined
  true

movingMouseMove = (e) -> #{{{2
  return if not movingKlynge

  dx = movingX - movingX0
  dy = movingY - movingY0
  menuRadius = menuSize + boxSize * Math.sqrt(2)
  hideMenuItems() if dx*dx + dy*dy > menuRadius*menuRadius
  console.log "xxxx", dx*dx + dy*dy < boxSize * boxSize / 4 and Date.now() - clickTime < 1000

  klynge = movingKlynge
  e.preventDefault()
  dx = e.screenX - movingX
  dy = e.screenY - movingY
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
edges = []
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
      $div.data "klynge", klynge
      $div.css
        width: boxSize - 2*boxPadding
        color: qp.hashColorDark klynge.title
        padding: boxPadding
        borderRadius: boxPadding
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
      for child in branch.adhl
        if !acc.added[child.klynge]
          console.log klyngeId, child.klynge, acc.added
          acc.links.push [klyngeId, child.klynge]
          return klyngeWalk child.klynge, n - 1, callback, done, salt, acc
      hash = qp.prng hash
    done acc.arr, acc.links

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
  klyngeWalk root, 50, handleResult, handleResult

requestKlynge = (klyngeId) -> #{{{2
  if klynger[klyngeId]
    klynge = klynger[klyngeId]
    nodes.push klynge if !klynge.added
    klynge.added = true
    return
  return if graphLoading
  graphLoading = true
  loadKlynge klyngeId, (klynge) ->
    if recur > 0
      klynge.children = eachBranch
      --recur
    else
      klynge.children = 0
    graphLoading = false
    update()

update = -> #{{{2
  i = 0
  for _, klynge of klynger
    klynge.added = false
  nodes = [klynger[root]]
  klynger[root].added = true
  links = []
  while i < nodes.length
    klynge = nodes[i]
    if klynge.adhl
      children = klynge.adhl.slice 0, klynge.children || 0
      for child in children
        requestKlynge child.klynge
    ++i

  for klynge in nodes
    full = true
    if klynge.adhl
      for child in klynge.adhl.slice 0, (klynge.children || 0) + backlinks
        child = klynger[child.klynge]
        if child?.added
          links.push
            source: klynge
            target: child
        else
          full = false
  for _, klynge of klynger
    klynge.children = 0 if !klynge.added
  draw()

$ -> #{{{1
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
          nodesOld = [max]
          console.log "root:", max
          initDraw()
          root = max.klynge
          requestKlynge root
  
  # Handle seach request and location.hash {{{2
  
  ($ "#search").on "submit", ->
    search()
    false
  if location.hash
    ($ "#query").val location.hash.slice(1)
    search()
  ($ "#search").focus()
