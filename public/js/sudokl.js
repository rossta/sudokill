Sudokl = (function() {

  var instanceMethods = {
    constructor: function(selector) {
      this.selector = selector;
      this.$sudokl  = $(selector);

      this.board    = new Board();
      this.board.appendTo(this.$sudokl);

      this.$msg     = $("<div>");
      this.$msg.attr("id", "msg").appendTo(this.$sudokl);
    },

    connect: function() {
      var self = this;
      ws = new WebSocket("ws://localhost:8080/");
      ws.onmessage = function(evt) {
        self.$msg.append("<p>"+evt.data+"</p>").scrollTop(self.$msg.height());
      };
      ws.onclose = function() {
        console.log("ws:","socket closed");
      };
      ws.onopen = function() {
        console.log("ws:","connected...");
        ws.send("hello server");
      };
    },

    echo: function() {
      var self = this;
      ws = new WebSocket("ws://localhost:8080/");
      ws.onmessage = function(evt) {
        self.$msg.append("<p>"+evt.data+"</p>");
      };
      ws.onclose = function() { console.log("ws:","socket closed"); };
      ws.onopen = function() { console.log("ws:","connected..."); ws.send("hello server"); };
    }
  },

  classMethods = {
    play : function(opts) {
      var sudokl = new Sudokl(opts);
      sudokl.connect();
    }
  };

  var Board = Base.extend({
    constructor: function() {
      var self = this, $cell, $row;
      self.$element = $("<div>");
      self.$element.attr("id", "board").addClass("table");
      for(var i = 0; i < 9; i++) {
        $row = $("<div>");
        $row.addClass("row").attr("id", "row_" + i);
        self.$element.append($row);
        for(var j = 0; j < 9; j++) {
          $cell = $("<div>");
          $cell.addClass("cell").attr("id","cell_" + i + "_" + j).attr("name", "cell["+i+"]["+j+"]");
          $row.append($cell);
        }
      }

    },
    appendTo: function($el) {
      this.$element.appendTo($el);
    }
  });


  return Base.extend(instanceMethods, classMethods);
})();