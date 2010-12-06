Sudocoup = (function() {

  var instanceMethods = {
    constructor: function(selector, opts) {
      var self = this;
      self.selector = "#" + selector;
      self.$sudocoup  = $(self.selector);

      opts = opts || {};
      self.mode     = opts['mode'] || 'normal';
      self.board    = new GameBoard("game_board", self.selector);

      self.$status = buildContainer("game_status");
      self.$sudocoup.append(self.$status);

      self.client   = new WebSocketClient(this, self.mode);

      self.$gameLog = buildContainer("game_log");
      self.$sudocoup.append(self.$gameLog);
      self.score    = new ScoreBoard("score_board", "#game_log");
      self.messager = new Messager("#game_log");

      // listen for events
      self.$sudocoup
        .bind("send_message", function(e, text) {
          self.send(text);
        })
        .bind("connected", function() {
          self.show();
        });

      self.status("Enter your name and connect");
      return self;
    },

    show: function(mode) {
      var self = this, $board;
      mode = mode || 'show';
      self.board.build();
      self.score.build();
      if (!(self.mode == 'simple')) self.messager.show();
      self.$gameLog.show();

      $(".title").hide();
      $(".logo").show();
      $board = $("#game_board");
      self.$status.css({
        position:"absolute",
        top:$board.offset().top + $board.height() + "px",
        left:$board.offset().left + "px",
        width: $board.width()
      });

      return self;
    },

    // Example Sudocoup.game.connect("ws://linserv1.cims.nyu.edu:25252")
    connect: function(name, host, port) {
      var self = this;
      self.client.connect(name, host, port);
    },

    send: function(msg) {
      this.client.send(msg);
    },

    update: function(i, j, value) {
      var self = this;
      self.log("UPDATE", i, j, value);
      self.board.update(i, j, value);
      return self;
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

    status: function(msg) {
      var self = this, $msg = $("<div/>");
      $msg.text(msg).addClass("message");
      self.$status.empty().append($msg).show();
      self.log(msg);
      return self;
    },

    dispatch: function(message) {
      var self = this, value, json;
      if (message.match(/UPDATE|CREATE|SCORE|STATUS/)) {
        try {
          json = $.parseJSON(message);
        } catch (e) {
          self.log("Catch JSON parse error", e.toString());
          self.print(message);
        }
        switch (json.action) {
          case "UPDATE":
            value = json.value;
            self.update(value[0], value[1], value[2]);
            break;
          case "CREATE":
            self.create(json.values);
            break;
          case "SCORE":
            self.score.updateScore(json.players);
            break;
          case "STATUS":
            self.status(json.message);
            break;
          default:
            self.log("Unrecognized action", json.action, json);
        }
      } else {
        self.log(message);
        self.print(message);
      }
      return json;
    }
  },

  classMethods = {
    play : function(selector, opts) {
      this.game = new Sudocoup(selector, opts);
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
  },

  GameBoard = Base.extend({
    constructor: function(domId, container) {
      var self = this;
      self.hilite         = "#333333";
      self.none           = "none";
      self.domId          = domId;
      self.$selector      = $("#" + self.domId);
      self.dim            = 50;
      self.numberSquares  = new MultiArray(9, 9);
      self.backgroundSquares = new MultiArray(9, 9);
      $("<div />").attr("id", domId).appendTo(container);
    },
    update: function(i, j, number){
      var self = this,
          rtext = self.numberSquares[i][j],
          rsquare = self.backgroundSquares[i][j],
          hilite = self.hilite,
          none = self.none;
      _(self.backgroundSquares).each(function(row, k) {
        _(row).each(function(sq){
          if (i===k) {
            sq.attr({fill:hilite});
          } else {
            sq.attr({fill:none});
          }
        });
        row[j].attr({fill:hilite});
      });
      _(self.backgroundSquares[i]).each(function(sq) {
        sq.attr({fill:hilite});
      });
      rsquare.animate({fill:Raphael.getColor()},300, function() {
        rtext.attr({text: number});
        rsquare.animate({fill:none}, 300);
      });
      return rtext;
    },
    create: function(values) {
      var self = this;
      for(var i=0;i<values.length;i++) {
        var row = values[i];
        for(var j=0;j<row.length;j++) {
          var value = row[j];
          var square = self.numberSquares[i][j];
          if (value > 0) {
            square.attr({text:value});
            // self.update(i, j, value);
          } else {
            square.attr({text:" "});
            // self.update(i, j, " ");
          }
        }
      }
      self.squares.animate({fill:Raphael.getColor()}, 300, function() {
        self.squares.animate({fill:self.none}, 300);
      });
    },
    raphael: function() {
      var self = this;
      if (self.r) {
        self.r.clear();
      } else {
        self.r = Raphael(self.domId, 450, 450);
      }
      return self.r;
    },
    build: function() {
      var self = this,
          r   = self.raphael(),
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

      self.squares  = squares;
      self.groups   = groups;
    }
  },{}),

  ScoreBoard = Base.extend({
    constructor: function(domId, container) {
      var self = this;
      self.domId = domId;
      $("<div />").attr("id", domId).appendTo(container);
      self.$selector = $("#" + domId);
    },
    raphael: function() {
      var self = this;
      if (self.r) {
        self.r.clear();
      } else {
        self.r = Raphael(self.domId, 450, 450);
      }
      return r;
    },

    updateScore: function(players) {
      var self = this, $score = self.$selector.find("#score");
      $score.find(".player").empty();
      _(players).each(function(player) {
        var $player = $("<div />");
        $("<div />").appendTo($player).addClass("name").text(player["name"]);
        $("<div />").appendTo($player).addClass("current_time").text("Time: " + player["current_time"]);
        $("<div />").appendTo($player).addClass("max_time").addClass("hidden").text(player["max_time"]);
        $("<div />").appendTo($player).addClass("moves").text("Moves: " + player["moves"]);
        $player.addClass("player").appendTo($score);
      });
      return self;
    },

    build: function() {
      var self = this;
      self.$selector.empty();
      $("<div />").attr('id', 'score').appendTo(self.$selector);
      $("<div />").attr('id', 'queue').appendTo(self.$selector);
      var $score = $("#score");
      var $queue = $("#queue");
      self.$selector.addClass("table");
      $score.addClass("cell_top").append($("<div />").addClass("header").text("Now playing"));
      $queue.addClass("cell_top").append($("<div />").addClass("header").text("On deck"));
      return self;
    }
  }),

  MultiArray = function(rows, cols) {
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
  },

  Messager = Base.extend({
    constructor: function(selector) {
      var self = this;
      self.$selector  = $(selector);
      self.$msg       = $("<div />");
      self.$pane      = $("<div />");
      self.$form      = $("<form></form>");
      self.$input     = $("<input type='text' name='message' placeholder='Say anything...' />");

      self.$msg.attr("id", "msg").appendTo(selector);
      self.$msg.hide();
      self.$pane.addClass("pane").appendTo(self.$msg);

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
      return this.$msg.addClass("visible");
    }

  }),

  WebSocketClient = Base.extend({
    constructor: function(game, mode) {
      var self = this;
      self.game = game;
      self.$connectForm = buildConnectForm();
      self.$status      = buildContainer("websocket_status");

      $(game.selector).append(self.$connectForm).append(self.$status);

      mode = mode || 'normal';
      self.$connectForm.addClass("websocket welcome").addClass(mode);

      self.$connectForm.submit(function(){
          var $this = $(this),
              host = $this.find('input[name=host]').val(),
              port = $this.find('input[name=port]').val(),
              name = $this.find('input[name=name]').val();
          self.status("Connecting");
          self.connect(name, host, port);
          return false;
        }).
        bind("connected", function(){
          $(this).find("input.submit").attr("value", "Disconnect");
          self.$connectForm.removeClass("welcome").addClass("connected");
          self.status("Connected");
        }).
        bind("disconnected", function() {
          $(this).find("input.submit").attr("value", "Connect");
          self.$connectForm.removeClass("connected").addClass("welcome");
          self.status("Not connected");
        }).
        delegate("input.submit[value=Disconnect]", "click", function(){
          self.close();
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
      self.name = name;

      game.log("ws:", "connecting to " + url);
      ws.onmessage = function(e) {
        var message = e.data.replace(/\r\n$/, "");
        game.dispatch(message);
        game.log("ws:", message, e);
      };
      ws.onclose = function() {
        game.log("ws:", "closed connection.");
        game.print("Bye!");
        self.$connectForm.trigger("disconnected");
      };
      ws.onopen = function() {
        game.log("ws:", "connected!");
        self.send(["NEW CONNECTION", name].join(PIPE));
        self.$connectForm.trigger("connected");
      };
      return ws;
    },
    close: function() {
      var self = this;
      self.ws.close();
    },
    send: function(msg) {
      this.ws.send(msg + EOL);
    },
    status: function(msg) {
      var self = this;
      if (self.statusTimeout) clearTimeout(self.statusTimeout);
      self.$status.text(msg).show();
      self.statusTimeout = setTimeout(function() {
        self.$status.fadeOut(1000);
      }, 2500);
    }
  }),

  userAgentName = function() {
    var name = "Unknown Agent";
    if (navigator.userAgent) name = navigator.userAgent.slice(0, 15);
    return name;
  },
  PIPE = "|",
  EOL = "\r\n",

  buildConnectForm = function() {
    var $connectForm = $("<form></form>");
    $connectForm.append("<div class='required'></div>");
    var $name = $connectForm.find("div.required");
        $name.append("<input id='s_name' type='text' name='name' class='name' placeholder='Your name please' autofocus='true' />");
        $name.append("<label for='s_name' class='name'>Your name please</label>");

    var $toggle = $("<a></a>").attr("href", "#").text("Options").addClass("toggle");
        $name.append($toggle);

    $connectForm.append("<div class='optional'></div>");
    var $opts = $connectForm.find("div.optional");
        $opts.append("<label for='s_host' class='host'>Host</label>");
        $opts.append("<input id='s_host' type='text' name='host' class='host'/>");
        $opts.append("<label for='s_port' class='port'>Port</label>");
        $opts.append("<input id='s_port' type='text' name='port' class='port' />");

    $connectForm.append("<input type='submit' name='connection' value='Connect' class='submit' />");
    return $connectForm;
  },

  buildContainer = function(domId) {
    var $status = $("<div />");
    $status.attr("id", domId).hide();
    return $status;
  };

  classMethods.GameBoard  = GameBoard;
  classMethods.ScoreBoard = ScoreBoard;
  classMethods.Messager   = Messager;
  classMethods.WebSocketClient = WebSocketClient;

  return Base.extend(instanceMethods, classMethods);
})();