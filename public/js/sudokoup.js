Sudokoup = (function() {

  var instanceMethods = {
    constructor: function(selector) {
      var self = this;
      self.selector = "#" + selector;
      self.$sudokoup  = $(selector);

      self.board    = new SuBoard(selector);
      self.score    = new ScoreTable();
      self.messager = new Messager();
      self.client   = new WebSocketClient(this);

      self.board.build();

      self.$connectForm = $("<form><input value='Connect' type='submit'/><input value='Disconnect' type='button'/></form>");
      $('body').append(this.$connectForm);
      self.$connectForm.submit(function(){
        self.client.connect();
        return false;
      }).find("input[value=Disconnect]").click(function(){
        self.client.close();
        return false;
      });
    },

// Example Sudokoup.game.connect("ws://linserv1.cims.nyu.edu:25252")
    connect: function(url) {
      this.client.connect(url);
    },

    update: function(i, j, value) {
      console.log("UPDATE", i, j, value);
      this.board.update(i, j, value);
      return this;
    },

    create: function(values) {
      this.board.create(values);
      return this;
    },

    dispatch: function(message) {
      var self = this;
      try {
        var json = $.parseJSON(message);
        switch (json.action) {
          case "UPDATE":
            self.update(json[0], json[1], json[2]);
            break;
          case "CREATE":
            self.create(json.values);
            break;
          default:
            console.log("Unrecognized action", json.action, json);
        }
      } catch (e) {
        console.log("Error parsing JSON", e.toString());
      }
      return json;
    }
  },

  classMethods = {
    play : function(opts) {
      var sudokoup = new Sudokoup(opts);
      // sudokoup.connect();
      this.game = sudokoup;
    }
  };

  var SuBoard = Base.extend({
    constructor: function(selector) {
      this.r = Raphael(selector, 450, 450);
      this.dim            = 50;
      this.numberSquares  = new MultiArray(9, 9);
      this.backgroundSquares = new MultiArray(9, 9);
    },
    update: function(i, j, number){
      var rtext = this.numberSquares[i][j],
      rsquare = this.backgroundSquares[i][j];
      rsquare.animate({fill:Raphael.getColor()},300, function() {
        rtext.attr({text: number});
        rsquare.animate({fill:"none"}, 300);
      });
      return rtext;
    },
    create: function(values) {
      var self = this;
      $(values).each(function(i, row) {
        $(row).each(function(j, value) {
          if (value > 0) {
            self.update(i, j, value);
          } else {
            self.update(i, j, "");
          }
        });
      });
    },
    build: function() {
      var r = this.r,
      groups  = r.set(),
      squares = r.set(),
      dim = 50,
      gDim = 3 * dim,
      start = 0,
      strokeColor = 'green',
      color = "hsb(" + start + ", 1, .5)",
      bcolor = "hsb(" + start + ", 1, 1)",
      group, square, text, x, y, cx, cy;

      r.rect(0, 0, gDim * 3, gDim * 3).attr({
        stroke: strokeColor,
        "stroke-opacity": 0.5,
        "stroke-width": 4
      });

      for(var i = 0; i < 3; i++) {
        y = i * gDim;
        for(var j = 0; j < 3; j++) {
          x = j * gDim;
          group = r.rect(x, y, gDim, gDim);
          groups.push(group);
        }
      }

      for(var i = 0; i < 9; i++) {
        y = i * dim;
        for(var j = 0; j < 9; j++) {
          color = "hsb(" + start + ", 1, .5)";
          bcolor = "hsb(" + start + ", 1, 1)";
          x = j * dim;
          cx = x + (dim/2);
          cy = y + (dim/2);

          square = r.rect(x, y, dim, dim);

          text = r.text(cx, cy, Math.floor(Math.random()*9) + 1).attr({
            fill: bcolor,
            "text-anchor": "middle",
            "font-size": "32px",
            "color": "white"
          });

          this.numberSquares[i][j] = text;
          this.backgroundSquares[i][j] = square;

          squares.push(square);
          start += 0.01;
        }
      }


      squares.attr({
        stroke: strokeColor,
        "stroke-opacity": 0.5,
        "stroke-width": 1
      });

      groups.attr({
        stroke: strokeColor,
        "stroke-opacity": 0.5,
        "stroke-width": 2
      });
    }
  },{});

  var ScoreTable = Base.extend({
    constructor: function() {
      this.numbers = new MultiArray(9, 9);
    }
  });

  var MultiArray = function(rows, cols) {
    var i;
    var j;
       var a = new Array(rows);
       for (i=0; i < rows; i++)
       {
           a[i] = new Array(cols);
           for (j=0; j < cols; j++)
           {
               a[i][j] = "";
           }
       }
       return(a);
  };

  var Messager = Base.extend({
    constructor: function() {
      this.$msg     = $("<div>");
      this.$msg.attr("id", "msg").appendTo('body');
    },

    log: function(message) {
      var self = this;
      self.$msg.append("<p>"+message+"</p>").scrollTop(self.$msg.height());
      return message;
    }
  });

  var WebSocketClient = Base.extend({
    constructor: function(game) {
      this.game = game;
    },
    connect: function(url) {
      var self = this,
      game = self.game,
      url = url || "ws://localhost:8080/";
      console.log("connecting to " + url);
      ws = new WebSocket(url);
      ws.onmessage = function(e) {
        var message = e.data.trim();
        game.dispatch(message);
        game.messager.log("Server >> " + message);
        console.log("ws: receiving message");
        console.log("ws: " + message, e);
      };
      ws.onclose = function() {
        game.messager.log("Websocket >> Closed connection.");
        console.log("ws:","socket closed");
      };
      ws.onopen = function() {
        console.log("ws:","connected...");
        ws.send("NEW CONNECTION\n");
      };
      self.ws = ws;
    },
    echo: function() {
      var self = this;
      ws = new WebSocket("ws://localhost:8080/");
      ws.onmessage = function(e) { console.log("ws:", e.data, e); };
      ws.onclose = function() { console.log("ws:","socket closed"); };
      ws.onopen = function() { console.log("ws:","connected..."); ws.send("hello server"); };
    },
    close: function() {
      this.ws.close();
    }
  });

  return Base.extend(instanceMethods, classMethods);
})();