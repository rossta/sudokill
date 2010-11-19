Sudokoup = (function() {

  var instanceMethods = {
    constructor: function(selector) {
      var self = this;
      self.selector = "#" + selector;
      self.$sudokoup  = $(selector);
      $("<div id='board' />").appendTo(self.selector);

      self.board    = new GameBoard('board');
      self.score    = new ScoreTable();
      self.messager = new Messager(self.selector);
      
      self.client   = new WebSocketClient(this);

      self.board.build();
    },

// Example Sudokoup.game.connect("ws://linserv1.cims.nyu.edu:25252")
    connect: function(name, host, port) {
      this.client.connect(name, host, port);
    },

    send: function(msg) {
      this.client.send(msg);
    },

    update: function(i, j, value) {
      this.log("UPDATE", i, j, value);
      this.board.update(i, j, value);
      return this;
    },

    create: function(values) {
      this.board.create(values);
      return this;
    },

    log: function() {
      console.log.apply(console, arguments);
      this.messager.log.apply(this.messager, arguments);
    },

    print: function(message) {
      this.messager.print(message);
    },

    dispatch: function(message) {
      var self = this, value;
      try {
        var json = $.parseJSON(message);
        switch (json.action) {
          case "UPDATE":
            value = json.value;
            self.update(value[0], value[1], value[2]);
            break;
          case "CREATE":
            self.create(json.values);
            break;
          default:
            self.log("Unrecognized action", json.action, json);
        }
      } catch (e) {
        console.log("Catch JSON parse error", e.toString());
        self.print(message);
      }
      return json;
    }
  },

  classMethods = {
    play : function(selector) {
      this.game = new Sudokoup(selector);
      return this.game;
    }
  };

  var GameBoard = Base.extend({
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
    constructor: function(selector) {
      this.$msg     = $("<div>");
      this.$pane    = $("<div>");
      this.$msg.attr("id", "msg").appendTo(selector);
      this.$pane.attr("id", "pane").appendTo(this.$msg);
    },

    log: function() {
      var self = this,
      message = _(arguments).toArray();
      self.$pane.append("<p>"+message.join(" ")+"</p>").scrollTop(self.$pane.attr("scrollHeight"));
      return message;
    },

    print: function(message) {
      this.log(message);
      return message;
    }
  });

  var WebSocketClient = Base.extend({
    constructor: function(game) {
      var self = this;
      self.game = game;
      self.$connectForm = $("<form></form>");
      $(game.selector).append(self.$connectForm);

      self.$connectForm.append("<div class='required'></div>");
      var $name = self.$connectForm.find("div.required");
          $name.append("<label for='s_name'>Name</label>");
          $name.append("<input id='s_name' type='text' name='name' class='name' />");

      var $toggle = $("<a></a>").attr("href", "#").text("Options").addClass("toggle");
          $name.append($toggle);

      self.$connectForm.append("<div class='optional'></div>");
      var $opts = self.$connectForm.find("div.optional");
          $opts.append("<label for='s_host' class='host'>Host</label>");
          $opts.append("<input id='s_host' type='text' name='host' class='host'/>");
          $opts.append("<label for='s_port' class='port'>Port</label>");
          $opts.append("<input id='s_port' type='text' name='port' class='port' />");
      self.$connectForm.append("<input type='submit' name='connection' value='Connect' class='submit' />");

      self.$connectForm.submit(function(){
          var $this = $(this),
              host = $this.find('input[name=host]').val(),
              port = $this.find('input[name=port]').val(),
              name = $this.find('input[name=name]').val();

          self.connect(name, host, port);
          return false;
        }).
        bind("connected", function(){
          $(this).find("input.submit").attr("value", "Disconnect");
        }).
        delegate("input.submit[value=Disconnect]", "click", function(){
          self.close();
          $(this).attr("value", "Connect");
          return false;
        }).
        delegate("a.toggle", "click", function() {
          var text = $(this).text();
          text = text == "Options" ? "Hide" : "Options";
          $(this).text(text);
          $(this).parents("form").find(".optional").toggle();
          return false;
        });

    },
    connect: function(name, host, port) {
      var self = this,
      game  = self.game,
      name  = name || 'Patron ' + userAgentName(),
      host  = host || 'localhost',
      port  = port || '8080',
      url   = "ws://" + host + ":" + port + "/",
      ws = new WebSocket(url);
      self.ws = ws;
      game.log("ws:", "connecting to " + url);
      ws.onmessage = function(e) {
        var message = e.data.trim();
        game.dispatch(message);
        game.log("ws:", message, e);
      };
      ws.onclose = function() {
        game.log("ws:", "closed connection.");
      };
      ws.onopen = function() {
        game.log("ws:", "connected!");
        self.$connectForm.trigger("connected");
        ws.send(["NEW CONNECTION", name].join("|") + "\n");
      };
    },
    close: function() {
      this.ws.close();
    },
    send: function(msg) {
      this.ws.send(msg + "\n");
    }
  });

  var userAgentName = function() {
    var name = "Unknown Agent";
    if (navigator.userAgent) name = navigator.userAgent.slice(0, 30);
    return name;
  };

  classMethods.GameBoard = GameBoard;
  classMethods.ScoreTable = ScoreTable;
  classMethods.Messager = Messager;
  classMethods.WebSocketClient = WebSocketClient;

  return Base.extend(instanceMethods, classMethods);
})();