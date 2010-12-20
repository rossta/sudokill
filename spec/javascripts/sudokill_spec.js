describe("Sudokill", function() {
  var sudokill;

  describe("constructor", function() {
    it("should have a board, score table, messager, websocket client", function() {
      sudokill = new Sudokill("sudokill").show();
      expect(sudokill.board).toEqual(jasmine.any(Sudokill.GameBoard));
      expect(sudokill.score).toEqual(jasmine.any(Sudokill.ScoreBoard));
      expect(sudokill.messager).toEqual(jasmine.any(Sudokill.Messager));
      expect(sudokill.client).toEqual(jasmine.any(Sudokill.WebSocketClient));
    });
    it("should build the game board", function(){
      spyOn(Sudokill.GameBoard.prototype, "build");
      new Sudokill('sudokill').show();
      expect(Sudokill.GameBoard.prototype.build).toHaveBeenCalled();
    });
    it("should append div#game_board to selector", function(){
      sudokill = new Sudokill('sudokill').show();
      var $sudokill = $("#sudokill");
      expect($sudokill).toHaveSelector("#game_board");
    });
  });
  describe("connect", function(){
    it("should call client connect", function() {
      sudokill = Sudokill.setup('sudokill');
      spyOn(sudokill.client, "connect");
      sudokill.connect("Rossta", "localhost", "8080");
      expect(sudokill.client.connect).toHaveBeenCalledWith("Rossta", "localhost", "8080");
    });
  });
  describe("send", function() {
    it("should call client send", function() {
      sudokill = Sudokill.setup('sudokill');
      spyOn(sudokill.client, "send");
      sudokill.send("message");
      expect(sudokill.client.send).toHaveBeenCalledWith("message");
    });
  });
  describe("update", function() {
    it("should update the board", function() {
      sudokill = Sudokill.setup('sudokill');
      spyOn(sudokill.board, "update");
      sudokill.update(0, 0, 9, 1, "ok");
      expect(sudokill.board.update).toHaveBeenCalledWith(0, 0, 9, 1, "ok");
    });
  });
  describe("create", function() {
    it("should create the board", function() {
      sudokill = Sudokill.setup('sudokill');
      spyOn(sudokill.board, "create");
      sudokill.create([1, 2, 3]);
      expect(sudokill.board.create).toHaveBeenCalledWith([1, 2, 3]);
    });
  });
  describe("dispatch", function() {
    it("should print text message", function() {
      sudokill = Sudokill.setup('sudokill');
      spyOn(sudokill.messager, "print");
      sudokill.dispatch("text message");
      expect(sudokill.messager.print).toHaveBeenCalledWith("text message");
    });
    describe("{ action: UPDATE }", function() {
      it("should update game board with given values", function() {
        var json = "{\"action\":\"UPDATE\",\"status\":\"ok\",\"value\":[1, 2, 3, 1]}";
        sudokill = Sudokill.setup('sudokill');
        spyOn(sudokill.board, "update");
        sudokill.dispatch(json);
        expect(sudokill.board.update).toHaveBeenCalledWith(1, 2, 3, 1, "ok");
      });
    });
    describe("{ action: CREATE }", function() {
      it("should create game board with given values", function() {
        var json = "{\"action\":\"CREATE\",\"values\":[1, 2, 3]}";
        sudokill = Sudokill.setup('sudokill');
        spyOn(sudokill.board, "create");
        sudokill.dispatch(json);
        expect(sudokill.board.create).toHaveBeenCalledWith([1, 2, 3]);
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
        sudokill = Sudokill.setup('sudokill');
        spyOn(sudokill.score, "updateScore");
        sudokill.dispatch(json);
        expect(sudokill.score.updateScore).toHaveBeenCalledWith([
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
        sudokill = Sudokill.setup('sudokill');
        spyOn(sudokill.score, "updateQueue");
        sudokill.dispatch(json);
        expect(sudokill.score.updateQueue).toHaveBeenCalledWith([
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
      var json, sudokill, status;
      beforeEach(function() {
        sudokill = Sudokill.setup('sudokill');
        json = "{\"action\":\"STATUS\",\"state\":\"in_progress\", \"message\":\"Game is now in progress\"}";
      });
      it("should print message in game status div", function() {
        sudokill.dispatch(json);
        status = $("#game_status").text();
        expect(status).toEqual("Game is now in progress");
      });
      it("should trigger game state event", function() {
        statusSpy = jasmine.createSpy("status");
        $("#sudokill").bind("game_state", function(e, state) { statusSpy(state); });
        sudokill.dispatch(json);
        expect(statusSpy).toHaveBeenCalledWith("in_progress");
      });
    });
    describe("{ action: COMMAND }", function() {
      it("should trigger game command event", function() {
        var sudokill = Sudokill.setup('sudokill');
        var json = "{\"action\":\"COMMAND\",\"command\":\"ADD\"}";
        var commandSpy = jasmine.createSpy("command");
        $("#sudokill").bind("game_command", function(e, state) { commandSpy(state); });
        sudokill.dispatch(json);
        expect(commandSpy).toHaveBeenCalledWith("ADD");
      });
    });
    describe("listen", function() {
      it("should bind event to selector", function() {
        sudokill = Sudokill.setup('sudokill');
        callback = jasmine.createSpy("listener");
        sudokill.listen("foobar", callback);
        $("#sudokill").trigger("foobar");
        expect(callback).toHaveBeenCalled();
      });
    });
    describe("events", function() {
      describe("send_message", function() {
        it("should send given text", function() {
          sudokill = Sudokill.setup('sudokill');
          spyOn(sudokill, "send");
          $("#sudokill").trigger("send_message", "What a game!");
          expect(sudokill.send).toHaveBeenCalledWith("What a game!");
        });
      });
      describe("connected", function() {
        it("should show game", function() {
          sudokill = Sudokill.setup('sudokill');
          spyOn(sudokill, "show");
          $("#sudokill").trigger("connected");
          expect(sudokill.show).toHaveBeenCalled();
        });
      });
    });
  });
});