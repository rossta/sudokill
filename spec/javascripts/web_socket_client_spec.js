describe("WebSocketClient", function() {
  var game = {
    selector: '#sudocoup',
    log: function() {},
    print: function() {},
    dispatch: function() {},
    status: function() {},
    listen:function() {}
  },
  fakeWebSocket = function(url) {
    var methods = {
      URL: url,
      send: function() {},
      close: function() {}
    };
    return methods;
  },
  createClient = function() {
    return new Sudocoup.WebSocketClient(game);
  };

  beforeEach(function() {
    spyOn(window, "WebSocket").andCallFake(fakeWebSocket);
  });
  describe("constructor", function() {
    it("should append the jquery form: $connectForm", function() {
      var client = new Sudocoup.WebSocketClient(game);
      expect(client.$connectForm).toEqual(jasmine.any($));
      expect(client.$connectForm).toHaveClass("websocket");
      expect(client.$connectForm).toHaveClass("welcome");
    });
    it("should add mode class to form", function() {
      var original = Sudocoup.Settings.mode;
      var client1 = new Sudocoup.WebSocketClient(game);
      expect(client1.$connectForm).toHaveClass("normal");
      expect(client1.$connectForm).not.toHaveClass("simple");

      Sudocoup.Settings.mode = "simple";
      var client2 = new Sudocoup.WebSocketClient(game);
      expect(client2.$connectForm).toHaveClass("simple");
      expect(client2.$connectForm).not.toHaveClass("normal");
      Sudocoup.Settings.mode = original;
    });
    it("should append form to game selector", function() {
      var client = new Sudocoup.WebSocketClient(game);
      var $game = $(game.selector);
      expect($game).toHaveSelector('form.websocket');
    });
    it("should inputs and labels to form", function() {
      var client = new Sudocoup.WebSocketClient(game);
      var $form = $('form.websocket');
      expect($form).toHaveSelector('input[name=name]');
      expect($form).toHaveSelector('input[name=host]');
      expect($form).toHaveSelector('input[name=port]');
      expect($form).toHaveSelector('input[type=submit]');
      expect($form).toHaveSelector('label.name');
      expect($form).toHaveSelector('label.host');
      expect($form).toHaveSelector('label.port');
    });
    it('should initialize host value to hostname', function() {
      var client = new Sudocoup.WebSocketClient(game), websocket;
      var hostname = new Sudocoup.Location().hostname();
      var $host = $('input[name=host]');
      expect($host.val()).toEqual(hostname);
    });
  });

  describe("events", function() {
    describe("game_state", function() {
      var client,websocket,$form;

      beforeEach(function() {
        spyOn(game, "listen").andCallFake(function(event, callback) {
          return $("#sudocoup").bind(event, callback);
        });
        client = createClient();
        websocket = client.connect();
        $form = $('form.websocket');
        spyOn(websocket, "send");
      });
    });
    describe("submit", function() {
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
      it("should update game status: connecting", function() {
        var client = createClient();
        var $form = $('form.websocket');
        var status;
        $form.submit();
        status = $("#websocket_status").text();
        expect(status).toEqual("Connecting");
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
      it("should update status: connected", function() {
        var client = createClient();
        var $form = $('form.websocket');
        var status;
        $form.trigger("connected");
        status = $("#websocket_status").text();
        expect(status).toEqual("Connected");
      });
    });
    describe("disconnected", function() {
      it("should change submit value", function() {
        var client = createClient();
        var $form = $('form.websocket');
        var $button = $form.find('input.submit');
        $form.trigger("connected");
        $form.trigger("disconnected");
        expect($button.val()).toEqual("Connect");
      });
      it("should update form classes", function() {
        var client = createClient();
        var $form = $('form.websocket');
        $form.trigger("connected");
        $form.trigger("disconnected");
        expect($form).not.toHaveClass("connected");
        expect($form).toHaveClass("welcome");
      });
      it("should update status: not connected", function() {
        var client = createClient();
        var $form = $('form.websocket');
        var status;
        $form.trigger("connected");
        $form.trigger("disconnected");
        status = $("#websocket_status").text();
        expect(status).toEqual("Not connected");
      });
    });
  });

  describe("connect", function() {
    beforeEach(function() {
      spyOn(game, "log");
    });
    it("should create a new WebSocket with url to given host, port", function() {
      var client = createClient();
      var websocket = client.connect("Rossta", "localhost", "8080");
      expect(websocket.URL).toEqual("ws://localhost:8080/");
    });
    it("should set hostname from location if not given", function() {
      var client = createClient(), websocket;
      spyOn(client.location, "hostname").andReturn("linserv1.cims.nyu.edu");
      websocket = client.connect("Rossta");
      expect(websocket.URL).toEqual("ws://linserv1.cims.nyu.edu:8080/");
    });
    describe("ws.onmessage", function() {
      it("should forward event data to game dispatch", function() {
        var client = createClient();
        var websocket = client.connect();
        spyOn(client.game, "dispatch");
        websocket.onmessage({data:"foobar"});
        expect(client.game.dispatch).toHaveBeenCalledWith("foobar");
      });
    });
    describe("ws.onopen", function() {
      it("should send NEW CONNECTION message to websocket", function() {
        var client = createClient();
        var websocket = client.connect("Rossta");
        spyOn(websocket, "send");
        websocket.onopen();
        expect(websocket.send).toHaveBeenCalledWith("NEW CONNECTION|Rossta\r\n");
      });
      it("should trigger 'connected' event on form", function() {
        var client = createClient();
        var websocket = client.connect("Rossta");
        var callback = jasmine.createSpy("connected callback");
        spyOn(websocket, "send");
        client.$connectForm.bind("connected", callback);
        websocket.onopen();
        expect(callback).toHaveBeenCalled();
      });
    });
    describe("ws.onclose", function() {
      it("should say goodbye", function() {
        var client = createClient();
        var websocket = client.connect();
        spyOn(client.game, "print");
        websocket.onclose();
        expect(client.game.print).toHaveBeenCalledWith("Bye!");
      });
      it("should trigger 'disconnected' event on form", function() {
        var client = createClient();
        var websocket = client.connect();
        var callback = jasmine.createSpy("disconnected callback");
        client.$connectForm.bind("disconnected", callback);
        websocket.onclose();
        expect(callback).toHaveBeenCalled();
      });
    });
  });

  describe("close", function() {
    it("should close websocket", function() {
      var client = createClient();
      var websocket = client.connect();
      spyOn(websocket, "close");
      client.close();
      expect(websocket.close).toHaveBeenCalled();
    });
  });

  describe("send", function() {
    it("should send formatted message to websocket", function() {
      var client = createClient();
      var websocket = client.connect();
      spyOn(websocket, "send");
      client.send("foobar");
      expect(websocket.send).toHaveBeenCalledWith("foobar\r\n");
    });
  });
});