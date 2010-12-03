describe("Sudocoup", function() {

  describe("constructor", function() {
    it("should have a board, score table, messager, websocket client", function() {
      var sudocoup = new Sudocoup("sudocoup").show();
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
      var sudocoup = new Sudocoup('sudocoup').show(),
      $sudocoup = $("#sudocoup");
      expect($sudocoup).toHaveSelector("#game_board");
    });
  });
  describe("connect", function(){
    it("should call client connect", function() {
      var sudocoup = Sudocoup.setup('sudocoup');
      spyOn(sudocoup.client, "connect");
      sudocoup.connect("Rossta", "localhost", "8080");
      expect(sudocoup.client.connect).toHaveBeenCalledWith("Rossta", "localhost", "8080");
    });
  });
  describe("send", function() {
    it("should call client send", function() {
      var sudocoup = Sudocoup.setup('sudocoup');
      spyOn(sudocoup.client, "send");
      sudocoup.send("message");
      expect(sudocoup.client.send).toHaveBeenCalledWith("message");
    });
  });
  describe("update", function() {
    it("should update the board", function() {
      var sudocoup = Sudocoup.setup('sudocoup');
      spyOn(sudocoup.board, "update");
      sudocoup.update(0, 0, 9);
      expect(sudocoup.board.update).toHaveBeenCalledWith(0, 0, 9);
    });
  });
  describe("create", function() {
    it("should create the board", function() {
      var sudocoup = Sudocoup.setup('sudocoup');
      spyOn(sudocoup.board, "create");
      sudocoup.create([1, 2, 3]);
      expect(sudocoup.board.create).toHaveBeenCalledWith([1, 2, 3]);
    });
  });
  describe("dispatch", function() {
    it("should print text message", function() {
      var sudocoup = Sudocoup.setup('sudocoup');
      spyOn(sudocoup.messager, "print");
      sudocoup.dispatch("text message");
      expect(sudocoup.messager.print).toHaveBeenCalledWith("text message");
    });
    describe("{ action: UPDATE }", function() {
      it("should update game board with given values", function() {
        var json = "{\"action\":\"UPDATE\",\"value\":[1, 2, 3]}";
        var sudocoup = Sudocoup.setup('sudocoup');
        spyOn(sudocoup.board, "update");
        sudocoup.dispatch(json);
        expect(sudocoup.board.update).toHaveBeenCalledWith(1, 2, 3);
      });
    });
    describe("{ action: CREATE }", function() {
      it("should create game board with given values", function() {
        var json = "{\"action\":\"CREATE\",\"values\":[1, 2, 3]}";
        var sudocoup = Sudocoup.setup('sudocoup');
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
        var sudocoup = Sudocoup.setup('sudocoup');
        spyOn(sudocoup.score, "update");
        sudocoup.dispatch(json);
        expect(sudocoup.score.update).toHaveBeenCalledWith([
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
    describe("events", function() {
      describe("send_message", function() {
        it("should send given text", function() {
          var sudocoup = Sudocoup.setup('sudocoup');
          spyOn(sudocoup, "send");
          $("#sudocoup").trigger("send_message", "What a game!");
          expect(sudocoup.send).toHaveBeenCalledWith("What a game!");
        });
      });
      describe("connected", function() {
        it("should show game", function() {
          var sudocoup = Sudocoup.setup('sudocoup');
          spyOn(sudocoup, "show");
          $("#sudocoup").trigger("connected");
          expect(sudocoup.show).toHaveBeenCalled();
        });
        it("should update status: connected", function() {
          var sudocoup = Sudocoup.setup('sudocoup');
          var status;
          $("#sudocoup").trigger("connected");
          status = $("#status").text();
          expect(status).toEqual("Connected");
        });
      });
      describe("disconnected", function() {
        it("should update status: not connected", function() {
          var sudocoup = Sudocoup.setup('sudocoup');
          var status;
          $("#sudocoup").trigger("disconnected");
          status = $("#status").text();
          expect(status).toEqual("Not connected");
        });
      });
    });
  });
});