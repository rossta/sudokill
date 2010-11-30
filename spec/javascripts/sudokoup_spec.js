describe("Sudokoup", function() {

  describe("constructor", function() {
    it("should have a board, score table, messager, websocket client", function() {
      var sudokoup = new Sudokoup("sudokoup").show();
      expect(sudokoup.board).toEqual(jasmine.any(Sudokoup.GameBoard));
      expect(sudokoup.score).toEqual(jasmine.any(Sudokoup.ScoreTable));
      expect(sudokoup.messager).toEqual(jasmine.any(Sudokoup.Messager));
      expect(sudokoup.client).toEqual(jasmine.any(Sudokoup.WebSocketClient));
    });
    it("should build the game board", function(){
      spyOn(Sudokoup.GameBoard.prototype, "build");
      new Sudokoup('sudokoup').show();
      expect(Sudokoup.GameBoard.prototype.build).toHaveBeenCalled();
    });
    it("should append div#board to selector", function(){
      var sudokoup = new Sudokoup('sudokoup').show(),
      $sudokoup = $("#sudokoup");
      expect($sudokoup).toHaveSelector("#board");
    });
  });
  describe("connect", function(){
    it("should call client connect", function() {
      var sudokoup = Sudokoup.setup('sudokoup');
      spyOn(sudokoup.client, "connect");
      sudokoup.connect("Rossta", "localhost", "8080");
      expect(sudokoup.client.connect).toHaveBeenCalledWith("Rossta", "localhost", "8080");
    });
    it("should update status: connecting", function() {
      var sudokoup = Sudokoup.setup('sudokoup');
      var $status = $("#status");
      spyOn(sudokoup.client, "connect");
      sudokoup.connect();
      expect($status.text()).toEqual("Connecting");
      expect($status).toBeVisible();
    });
  });
  describe("send", function() {
    it("should call client send", function() {
      var sudokoup = Sudokoup.setup('sudokoup');
      spyOn(sudokoup.client, "send");
      sudokoup.send("message");
      expect(sudokoup.client.send).toHaveBeenCalledWith("message");
    });
  });
  describe("update", function() {
    it("should update the board", function() {
      var sudokoup = Sudokoup.setup('sudokoup');
      spyOn(sudokoup.board, "update");
      sudokoup.update(0, 0, 9);
      expect(sudokoup.board.update).toHaveBeenCalledWith(0, 0, 9);
    });
  });
  describe("create", function() {
    it("should create the board", function() {
      var sudokoup = Sudokoup.setup('sudokoup');
      spyOn(sudokoup.board, "create");
      sudokoup.create([1, 2, 3]);
      expect(sudokoup.board.create).toHaveBeenCalledWith([1, 2, 3]);
    });
  });
  describe("dispatch", function() {
    it("should print text message", function() {
      var sudokoup = Sudokoup.setup('sudokoup');
      spyOn(sudokoup.messager, "print");
      sudokoup.dispatch("text message");
      expect(sudokoup.messager.print).toHaveBeenCalledWith("text message");
    });
    describe("{ action: UPDATE }", function() {
      it("should update game board with given values", function() {
        var json = "{\"action\":\"UPDATE\",\"value\":[1, 2, 3]}";
        var sudokoup = Sudokoup.setup('sudokoup');
        spyOn(sudokoup.board, "update");
        sudokoup.dispatch(json);
        expect(sudokoup.board.update).toHaveBeenCalledWith(1, 2, 3);
      });
    });
    describe("{ action: CREATE }", function() {
      it("should create game board with given values", function() {
        var json = "{\"action\":\"CREATE\",\"values\":[1, 2, 3]}";
        var sudokoup = Sudokoup.setup('sudokoup');
        spyOn(sudokoup.board, "create");
        sudokoup.dispatch(json);
        expect(sudokoup.board.create).toHaveBeenCalledWith([1, 2, 3]);
      });
    });
    describe("events", function() {
      describe("send_message", function() {
        it("should send given text", function() {
          var sudokoup = Sudokoup.setup('sudokoup');
          spyOn(sudokoup, "send");
          $("#sudokoup").trigger("send_message", "What a game!");
          expect(sudokoup.send).toHaveBeenCalledWith("What a game!");
        });
      });
      describe("connected", function() {
        it("should show game", function() {
          var sudokoup = Sudokoup.setup('sudokoup');
          spyOn(sudokoup, "show");
          $("#sudokoup").trigger("connected");
          expect(sudokoup.show).toHaveBeenCalled();
        });
        it("should update status: connected", function() {
          var sudokoup = Sudokoup.setup('sudokoup');
          var status;
          $("#sudokoup").trigger("connected");
          status = $("#status").text();
          expect(status).toEqual("Connected");
        });
      });
      describe("disconnected", function() {
        it("should update status: not connected", function() {
          var sudokoup = Sudokoup.setup('sudokoup');
          var status;
          $("#sudokoup").trigger("disconnected");
          status = $("#status").text();
          expect(status).toEqual("Not connected");
        });
      });
    });
  });
});