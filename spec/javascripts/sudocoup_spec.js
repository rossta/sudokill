describe("Sudocoup", function() {
  var sudocoup;

  describe("constructor", function() {
    it("should have a board, score table, messager, websocket client", function() {
      sudocoup = new Sudocoup("sudocoup").show();
      expect(sudocoup.board).toEqual(jasmine.any(Sudocoup.GameBoard));
      expect(sudocoup.score).toEqual(jasmine.any(Sudocoup.ScoreBoard));
      expect(sudocoup.messager).toEqual(jasmine.any(Sudocoup.Messager));
      expect(sudocoup.client).toEqual(jasmine.any(Sudocoup.WebSocketClient));
    });
    it("should build the game board", function(){
      spyOn(Sudocoup.GameBoard.prototype, "build");
      new Sudocoup('sudocoup').show();
      expect(Sudocoup.GameBoard.prototype.build).toHaveBeenCalled();
    });
    it("should append div#game_board to selector", function(){
      sudocoup = new Sudocoup('sudocoup').show();
      var $sudocoup = $("#sudocoup");
      expect($sudocoup).toHaveSelector("#game_board");
    });
  });
  describe("connect", function(){
    it("should call client connect", function() {
      sudocoup = Sudocoup.setup('sudocoup');
      spyOn(sudocoup.client, "connect");
      sudocoup.connect("Rossta", "localhost", "8080");
      expect(sudocoup.client.connect).toHaveBeenCalledWith("Rossta", "localhost", "8080");
    });
  });
  describe("send", function() {
    it("should call client send", function() {
      sudocoup = Sudocoup.setup('sudocoup');
      spyOn(sudocoup.client, "send");
      sudocoup.send("message");
      expect(sudocoup.client.send).toHaveBeenCalledWith("message");
    });
  });
  describe("update", function() {
    it("should update the board", function() {
      sudocoup = Sudocoup.setup('sudocoup');
      spyOn(sudocoup.board, "update");
      sudocoup.update(0, 0, 9);
      expect(sudocoup.board.update).toHaveBeenCalledWith(0, 0, 9);
    });
  });
  describe("create", function() {
    it("should create the board", function() {
      sudocoup = Sudocoup.setup('sudocoup');
      spyOn(sudocoup.board, "create");
      sudocoup.create([1, 2, 3]);
      expect(sudocoup.board.create).toHaveBeenCalledWith([1, 2, 3]);
    });
  });
  describe("dispatch", function() {
    it("should print text message", function() {
      sudocoup = Sudocoup.setup('sudocoup');
      spyOn(sudocoup.messager, "print");
      sudocoup.dispatch("text message");
      expect(sudocoup.messager.print).toHaveBeenCalledWith("text message");
    });
    describe("{ action: UPDATE }", function() {
      it("should update game board with given values", function() {
        var json = "{\"action\":\"UPDATE\",\"value\":[1, 2, 3]}";
        sudocoup = Sudocoup.setup('sudocoup');
        spyOn(sudocoup.board, "update");
        sudocoup.dispatch(json);
        expect(sudocoup.board.update).toHaveBeenCalledWith(1, 2, 3);
      });
    });
    describe("{ action: CREATE }", function() {
      it("should create game board with given values", function() {
        var json = "{\"action\":\"CREATE\",\"values\":[1, 2, 3]}";
        sudocoup = Sudocoup.setup('sudocoup');
        spyOn(sudocoup.board, "create");
        sudocoup.dispatch(json);
        expect(sudocoup.board.create).toHaveBeenCalledWith([1, 2, 3]);
      });
    });
    describe("{ action: SCORE }", function() {
      it("should update score board with player json", function() {
        var json = "";
        json += "{";
        json += "\"action\":\"SCORE\",";
        json +=   "\"players\": [";
        json +=     "{";
        json +=       "\"number\": 1,";
        json +=       "\"current_time\": 14,";
        json +=       "\"max_time\": 120,";
        json +=       "\"name\": \"Player 1\",";
        json +=       "\"moves\": 3";
        json +=     "},";
        json +=     "{";
        json +=       "\"number\": 2,";
        json +=       "\"current_time\": 25,";
        json +=       "\"max_time\": 120,";
        json +=       "\"name\": \"Player 2\",";
        json +=       "\"moves\": 2";
        json +=     "}";
        json +=   "]";
        json += "}";
        sudocoup = Sudocoup.setup('sudocoup');
        spyOn(sudocoup.score, "updateScore");
        sudocoup.dispatch(json);
        expect(sudocoup.score.updateScore).toHaveBeenCalledWith([
          {
            "number": 1,
            "current_time": 14,
            "max_time": 120,
            "name": "Player 1",
            "moves": 3
          },
          {
            "number": 2,
            "current_time": 25,
            "max_time": 120,
            "name": "Player 2",
            "moves": 2
          }
        ]);
      });
    });
    describe("{ action: QUEUE }", function() {
      it("should update score board with player json", function() {
        var json = "";
        json += "{";
        json += "\"action\":\"QUEUE\",";
        json +=   "\"players\": [";
        json +=     "{";
        json +=       "\"name\": \"Player 1\"";
        json +=     "},";
        json +=     "{";
        json +=       "\"name\": \"Player 2\"";
        json +=     "}";
        json +=   "]";
        json += "}";
        sudocoup = Sudocoup.setup('sudocoup');
        spyOn(sudocoup.score, "updateQueue");
        sudocoup.dispatch(json);
        expect(sudocoup.score.updateQueue).toHaveBeenCalledWith([
          {
            "name": "Player 1"
          },
          {
            "name": "Player 2"
          }
        ]);
      });
    });
    describe("{ action: STATUS }", function() {
      var json, sudocoup, status;
      beforeEach(function() {
        sudocoup = Sudocoup.setup('sudocoup');
        json = "{\"action\":\"STATUS\",\"state\":\"in_progress\", \"message\":\"Game is now in progress\"}";
      });
      it("should print message in game status div", function() {
        sudocoup.dispatch(json);
        status = $("#game_status").text();
        expect(status).toEqual("Game is now in progress");
      });
      it("should trigger game state event", function() {
        statusSpy = jasmine.createSpy("status");
        $("#sudocoup").bind("game_state", function(e, state) { statusSpy(state); });
        sudocoup.dispatch(json);
        expect(statusSpy).toHaveBeenCalledWith("in_progress");
      });
    });
    describe("{ action: COMMAND }", function() {
      it("should trigger game command event", function() {
        var sudocoup = Sudocoup.setup('sudocoup');
        var json = "{\"action\":\"COMMAND\",\"command\":\"ADD\"}";
        var commandSpy = jasmine.createSpy("command");
        $("#sudocoup").bind("game_command", function(e, state) { commandSpy(state); });
        sudocoup.dispatch(json);
        expect(commandSpy).toHaveBeenCalledWith("ADD");
      });
    });
    describe("listen", function() {
      it("should bind event to selector", function() {
        sudocoup = Sudocoup.setup('sudocoup');
        callback = jasmine.createSpy("listener");
        sudocoup.listen("foobar", callback);
        $("#sudocoup").trigger("foobar");
        expect(callback).toHaveBeenCalled();
      });
    });
    describe("events", function() {
      describe("send_message", function() {
        it("should send given text", function() {
          sudocoup = Sudocoup.setup('sudocoup');
          spyOn(sudocoup, "send");
          $("#sudocoup").trigger("send_message", "What a game!");
          expect(sudocoup.send).toHaveBeenCalledWith("What a game!");
        });
      });
      describe("connected", function() {
        it("should show game", function() {
          sudocoup = Sudocoup.setup('sudocoup');
          spyOn(sudocoup, "show");
          $("#sudocoup").trigger("connected");
          expect(sudocoup.show).toHaveBeenCalled();
        });
      });
    });
  });
});