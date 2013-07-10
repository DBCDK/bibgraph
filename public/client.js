// Generated by CoffeeScript 1.6.2
(function() {
  var $graph, klynger, requestKlynge, search, update;

  klynger = [];

  $graph = void 0;

  update = function() {
    var klynge, _i, _len, _results;

    $graph.empty();
    klynger = klynger.filter(function(klynge) {
      return klynge.adhl;
    });
    _results = [];
    for (_i = 0, _len = klynger.length; _i < _len; _i++) {
      klynge = klynger[_i];
      _results.push($graph.append("<div>" + klynge.title + " " + klynge.adhl[0][1] + "</div>"));
    }
    return _results;
  };

  requestKlynge = function(klynge) {
    return $.get("klynge/" + klynge, function(klynge) {
      klynger.push(klynge);
      return $.get("faust/" + klynge.faust[0], function(faust) {
        klynge.title = faust.title;
        update();
        return console.log(klynge);
      });
    });
  };

  search = function() {
    var query;

    query = ($("#query")).css({
      display: "none"
    }).val();
    klynger = [];
    qp.log("search", query);
    return $.get("search/" + query, function(result) {
      ($("#query")).css({
        display: "inline"
      }).val("");
      return result.map(function(faust) {
        return $.get("faust/" + faust, function(faust) {
          if (faust != null ? faust.klynge : void 0) {
            return requestKlynge(faust != null ? faust.klynge : void 0);
          }
        });
      });
    });
  };

  $(function() {
    $graph = $("#graph");
    return ($("#search")).on("submit", function() {
      search();
      return false;
    });
  });

}).call(this);
