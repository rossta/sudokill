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
    it("should be add visible class", function() {
      var messager = new Sudocoup.Messager('#sudocoup');
      var msgDiv = messager.$msg;
      messager.show();
      expect(msgDiv).toHaveLength(1);
      expect(msgDiv).toHaveClass("visible");
    });
  });

});