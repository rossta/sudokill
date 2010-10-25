Sudokl = (function() {

  var instanceMethods = {
    constructor: function(selector) {
      this.selector = "#" + selector;
      this.$sudokl  = $(selector);

      this.board    = new SuBoard(selector);
      this.board.build();

      this.score    = new ScoreTable();

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
    },
    update: function(i, j, number) {
      this.board.update(i, j, number);
    }
  },

  classMethods = {
    play : function(opts) {
      var sudokl = new Sudokl(opts);
      sudokl.connect();
      this.game = sudokl;
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

  return Base.extend(instanceMethods, classMethods);
})();