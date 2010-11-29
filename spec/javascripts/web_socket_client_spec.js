describe("WebSocketClient", function() {
  var game = {
    selector: '#sudokoup'
  },
  createClient = function() {
    return new Sudokoup.WebSocketClient(game);
  };
  
  // stub:
  //   log: function(){}
  //   print: function(){}
  //   dispatch: function(){}

  describe("constructor", function() {
    it("should append the jquery form: $connectForm", function() {
      var client = new Sudokoup.WebSocketClient(game);
      expect(client.$connectForm).toEqual(jasmine.any($));
      expect(client.$connectForm).toHaveClass("websocket");
      expect(client.$connectForm).toHaveClass("welcome");
    });
    it("should add mode class to form", function() {
      var client1 = new Sudokoup.WebSocketClient(game);
      expect(client1.$connectForm).toHaveClass("normal");
      expect(client1.$connectForm).not.toHaveClass("simple");

      var client2 = new Sudokoup.WebSocketClient(game, "simple");
      expect(client2.$connectForm).toHaveClass("simple");
      expect(client2.$connectForm).not.toHaveClass("normal");
    });
    it("should append form to game selector", function() {
      var client = new Sudokoup.WebSocketClient(game);
      var $game = $(game.selector);
      expect($game).toHaveSelector('form.websocket');
    });
    it("should inputs and labels to form", function() {
      var client = new Sudokoup.WebSocketClient(game);
      var $form = $('form.websocket');
      expect($form).toHaveSelector('input[name=name]');
      expect($form).toHaveSelector('input[name=host]');
      expect($form).toHaveSelector('input[name=port]');
      expect($form).toHaveSelector('input[type=submit]');
      expect($form).toHaveSelector('label.name');
      expect($form).toHaveSelector('label.host');
      expect($form).toHaveSelector('label.port');
    });
  });
  
  describe("events", function() {
    describe("submit form", function() {
      it("should call connect", function() {
        var client = createClient();
        var $form = $('form.websocket');
        spyOn(client, "connect");
        $("input[name=name]").val("Rossta");
        $("input[name=host]").val("localhost");
        $("input[name=port]").val("8080");
        $form.submit();
        expect(client.connect).toHaveBeenCalledWith("Rossta", "localhost", "8080");
      });
    });
    describe("connected", function() {
      it("should change submit value", function() {
        var client = createClient();
        var $button = $('form.websocket input.submit');
        $('form.websocket').trigger("connected");
        expect($button.val()).toEqual("Disconnect");
      });
      it("should update form classes", function() {
        var client = createClient();
        var $form = $('form.websocket');
        $form.trigger("connected");
        expect($form).toHaveClass("connected");
        expect($form).not.toHaveClass("welcome");
      });
    });
  });

  describe("connect", function() {

  });

  describe("close", function() {

  });

  describe("send", function() {

  });
});