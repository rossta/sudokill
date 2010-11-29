Sudokoup = (function() {

  var instanceMethods = {
    constructor: function(selector, opts) {
      var self = this;
      self.selector = "#" + selector;
      self.$sudokoup  = $(self.selector);
      $("<div id='board' />").appendTo(self.selector);
debugger
      opts = opts || {};

      self.mode     = opts['mode'] || 'normal';

      self.client   = new WebSocketClient(this, self.mode);
      self.board    = new GameBoard('board');
      self.score    = new ScoreTable();
      self.messager = new Messager(self.selector);

      // listen for events
      self.$sudokoup
        .bind("send_message", function(e, text) {
          self.send(text);
        })
        .bind("connected", function() {
          self.show();
        });
      return self;
    },

    show: function(mode) {
      var self = this;
      mode = mode || 'show';
      self.board.build();
      if (!(self.mode == 'simple')) self.messager.show();

      $(".title").hide();
      $(".logo").show();

      return self;
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
        self.log("Catch JSON parse error", e.toString());
        self.print(message);
      }
      return json;
    }
  },

  classMethods = {
    play : function(selector, opts) {
      this.game = new Sudokoup(selector, opts);
      return this.game;
    },
    setup: function(selector) {
      this.play(selector);
      return this.game.show();
    },
    simple: function(selector) {
      this.play(selector, { mode: 'simple'});
      return this.game.show();
    }
  };

  var GameBoard = Base.extend({
    constructor: function(selector) {
      this.hiliteColor = "#333333";
      this.selector = selector;
      this.dim            = 50;
      this.numberSquares  = new MultiArray(9, 9);
      this.backgroundSquares = new MultiArray(9, 9);
    },
    update: function(i, j, number){
      var rtext = this.numberSquares[i][j],
      rsquare = this.backgroundSquares[i][j];
      _(this.backgroundSquares).each(function(row) {
        _(row).each(function(sq){
          sq.attr({fill:"none"});
        });
      });
      _(this.backgroundSquares[i]).each(function(sq) {
        sq.attr({fill:"#666"});
      });
      _(this.backgroundSquares).each(function(row) {
        row[j].attr({fill:"#666"});
      });
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
    raphael: function() {
      if (this.r) {
        this.r.clear();
      } else {
        this.r = Raphael(this.selector, 450, 450);
      }
    },
    build: function() {
      this.raphael();
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
      var self = this;
      self.$selector  = $(selector);
      self.$msg       = $("<div>");
      self.$pane      = $("<div>");
      self.$form      = $("<form></form>");
      self.$input     = $("<input type='text' name='message' placeholder='Say anything...' />");

      self.$msg.attr("id", "msg").appendTo(selector);
      self.$msg.hide();
      self.$pane.attr("id", "pane").appendTo(self.$msg);

      self.$form.appendTo(self.$msg);
      self.$input.attr("id", "msg_field").appendTo(self.$form);

      self.$form.submit(function() {
        var $this   = $(this),
            message = self.$input.val();

        self.send(message);
        self.$input.val("");
        return false;
      });
    },

    print: function() {
      var self = this,
      message = _(arguments).toArray();
      self.$pane.append("<p>"+message.join(" ")+"</p>").scrollTop(self.$pane.attr("scrollHeight"));
      return message;
    },

    log: function(message) {
      if (window.console) window.console.log.apply(window.console, arguments);
      return message;
    },

    send: function(text) {
      this.$selector.trigger("send_message", text);
    },

    show: function() {
      return this.$msg.show();
    }

  });

  var WebSocketClient = Base.extend({
    constructor: function(game, mode) {
      var self = this;
      self.game = game;
      self.$connectForm = $("<form></form>");
      $(game.selector).append(self.$connectForm);
      mode = mode || 'normal';
      self.$connectForm.addClass("websocket welcome").addClass(mode);

      self.$connectForm.append("<div class='required'></div>");
      var $name = self.$connectForm.find("div.required");
          $name.append("<input id='s_name' type='text' name='name' class='name' placeholder='Your name please' autofocus='true' />");
          $name.append("<label for='s_name' class='name'>Your name please</label>");

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
          self.$connectForm.removeClass("welcome").addClass("connected");
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
        game.print("Bye!");
      };
      ws.onopen = function() {
        game.log("ws:", "connected!");
        self.$connectForm.trigger("connected");
        ws.send(["NEW CONNECTION", name].join(" | ") + "\r\n");
      };
    },
    close: function() {
      this.ws.close();
    },
    send: function(msg) {
      this.ws.send(msg + "\r\n");
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