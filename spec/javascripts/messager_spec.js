describe("Sudocoup.Messager", function() {

  beforeEach(fixture);
  afterEach(removeFixture);

  describe("log", function(){
    it("should print to console.log", function() {
      if (!window.console) window.console = { log: function() {} };
      spyOn(window.console, "log");
      var messager = new Sudocoup.Messager('#sudocoup');
      messager.log("Hello!");
      expect(window.console.log).toHaveBeenCalledWith("Hello!");
    });
  });

  describe("print", function() {
    it("should print to the message pane", function() {
      var messager = new Sudocoup.Messager('#sudocoup');
      messager.print("I know that's right!");
      var output = $("#msg .pane");
      expect(output.length).toEqual(1);
      expect(output.text()).toEqual("I know that's right!");
    });
    it("should append additional messages to pane", function() {
      var messager = new Sudocoup.Messager('#sudocoup');
      messager.print("That's awesome!");
      messager.print("I know that's right!");
      var paragraphs = $("#msg .pane p");
      expect(paragraphs.length).toEqual(2);
      expect(paragraphs.first().text()).toEqual("That's awesome!");
      expect(paragraphs.last().text()).toEqual("I know that's right!");
    });
  });

  describe("send", function() {
    it("should trigger send message event with text", function() {
      var messager = new Sudocoup.Messager('#sudocoup');
      var spy = jasmine.createSpy();
      $("#sudocoup").bind("send_message", function(e, text){
        spy(text);
      });
      messager.send("What a game!");
      expect(spy).toHaveBeenCalledWith("What a game!");
    });
  });

  describe("show", function() {
    var messager, humans;
    beforeEach(function() {
      humans = Sudocoup.Settings.humans;
    });
    afterEach(function() {
      Sudocoup.Settings.humans = humans;
    });

    it("should be add visible class", function() {
      messager = new Sudocoup.Messager('#sudocoup');
      var msgDiv = messager.$msg;
      messager.show();
      expect(msgDiv).toHaveLength(1);
      expect(msgDiv).toHaveClass("visible");
    });

    it("should not add join button while human settings are false", function() {
      Sudocoup.Settings.humans = false;
      messager = new Sudocoup.Messager('#sudocoup');
      var $button = $("input.join");
      expect($button).toHaveLength(0);
    });

  });

  describe("events", function() {
    var messager, callback;
    spyOnSend = function(callback) {
      return $("#sudocoup").bind("send_message", function(e, text){ callback(text); });
    };
    beforeEach(function() {
      messager = new Sudocoup.Messager("#sudocoup");
      sendMessage = jasmine.createSpy("send message callback");
      spyOnSend(sendMessage);
    });
    describe("select opponent", function() {
      it("should send opponent request", function() {
        var $select = $("select[name=opponent]");
        $select.val('OPPONENT|Vincent_Easy').change();
        expect(sendMessage).toHaveBeenCalledWith('OPPONENT|Vincent_Easy');
        expect($select.val()).toBeFalsy();
      });
    });
    describe("play", function() {
      it("should send PLAY message with density when play button clicked", function() {
        $("input.play").click();
        expect(sendMessage).toHaveBeenCalledWith("PLAY|33");
      });
      it("should change input value and class to 'stop'", function() {
        var $button = $("input.play");
        expect($button).not.toHaveClass("stop");
        expect($button.val()).toEqual("Play");
        $button.click();
        expect($button).not.toHaveClass("play");
        expect($button).toHaveClass("stop");
        expect($button.val()).toEqual("Stop");
      });
    });

    describe("stop", function() {
      it("should send STOP message when stop button clicked", function() {
        $("input.play").click();
        $("input.stop").click();
        expect(sendMessage).toHaveBeenCalledWith("STOP");
      });
      it("should change input value and class to 'play'", function() {
        var $button = $("input.play");
        $button.click();
        expect($button).not.toHaveClass("play");
        expect($button.val()).toEqual("Stop");
        $button.click();
        expect($button).not.toHaveClass("stop");
        expect($button).toHaveClass("play");
        expect($button.val()).toEqual("Play");
      });
    });

    describe("join_game", function() {
      it("should send JOIN message when join button clicked", function() {
        var $button = $("input.join");
        $button.click();
        expect(sendMessage).toHaveBeenCalledWith("JOIN");
      });
      it("should change input value and class to 'leave'", function() {
        var $button = $("input.join");
        expect($button).not.toHaveClass("leave");
        expect($button.val()).toEqual("Join game");
        $button.click();
        expect($button).not.toHaveClass("join");
        expect($button).toHaveClass("leave");
        expect($button.val()).toEqual("Leave game");
      });
    });

    describe("leave_game", function() {
      it("should send LEAVE message when leave button clicked", function() {
        $("input.join").click();
        var leaveMessage = jasmine.createSpy("leave message callback");
        spyOnSend(leaveMessage);
        $("input.leave").click();
        expect(leaveMessage).toHaveBeenCalledWith("LEAVE");
      });
      it("should change input value and class to 'join'", function() {
        var $button = $("input.join");
        $button.click();
        expect($button).not.toHaveClass("join");
        expect($button.val()).toEqual("Leave game");
        $button.click();
        expect($button).not.toHaveClass("leave");
        expect($button).toHaveClass("join");
        expect($button.val()).toEqual("Join game");
      });
    });

    describe("game states", function() {
      var $form;
      beforeEach(function() {
        $form = $('form.messager');
      });
      it("should display play button when game is over", function() {
        $("input.play").removeClass("play").addClass("stop").val("Stop");
        $("#sudocoup").trigger("game_state", "over");
        expect($form).not.toHaveSelector("input.stop");
        expect($form).toHaveSelector("input.play");
        expect($form.find("input.play").val()).toEqual("Play");
      });
      it("should display play button when game is waiting", function() {
        $("input.play").removeClass("play").addClass("stop").val("Stop");
        $("#sudocoup").trigger("game_state", "waiting");
        expect($form).not.toHaveSelector("input.stop");
        expect($form).toHaveSelector("input.play");
        expect($form.find("input.play").val()).toEqual("Play");
      });
      it("should display play button when game is ready", function() {
        $("input.play").removeClass("play").addClass("stop").val("Stop");
        $("#sudocoup").trigger("game_state", "ready");
        expect($form).not.toHaveSelector("input.stop");
        expect($form).toHaveSelector("input.play");
        expect($form.find("input.play").val()).toEqual("Play");
      });
      it("should display stop button when game is in progress", function() {
        $("input.play").removeClass("stop").addClass("play").val("Play");
        $("#sudocoup").trigger("game_state", "in_progress");
        expect($form).not.toHaveSelector("input.play");
        expect($form).toHaveSelector("input.stop");
        expect($form.find("input.stop").val()).toEqual("Stop");
      });
    });

  });

});