window.qp = {}

qp.log = (args...) ->
  qp._log? document.title, args...
