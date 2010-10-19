Sudoku = (function() {

  var instanceMethods = {
    initialize: function() {
      this.connect();
    },

    connect: function() {
      ws = new WebSocket("ws://localhost:8080/");
      ws.onmessage = function(evt) { $("#msg").append("<p>"+evt.data+"</p>"); };
      ws.onclose = function() { debug("socket closed"); };
      ws.onopen = function() {
        debug("connected...");
        ws.send("hello server");
      };
    }
  },

  classMethods = {
    begin : function(opts) {
      var sudoku = new Sudoku(opts);
      sudoku.connect();
    }
  };


  function debug(str){ $("#debug").append("<p>" +  str); };

  return Base.extend(instanceMethods, classMethods);
})();