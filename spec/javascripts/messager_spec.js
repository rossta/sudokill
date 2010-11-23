describe("Sudokoup.Messager", function() {

  beforeEach(fixture);
  afterEach(removeFixture);

  describe("log", function(){
    it("should print to console.log", function() {
      if (!window.console) window.console = { log: function() {} };
      spyOn(window.console, "log");
      var messager = new Sudokoup.Messager('#sudokoup');
      messager.log("Hello!");
      expect(window.console.log).toHaveBeenCalledWith("Hello!");
    });
  });

  describe("print", function() {
    it("should print to the message pane", function() {
      var messager = new Sudokoup.Messager('#sudokoup');
      messager.print("I know that's right!");
      var output = $("#pane");
      expect(output.length).toEqual(1);
      expect(output.text()).toEqual("I know that's right!");
    });
    it("should append additional messages to pane", function() {
      var messager = new Sudokoup.Messager('#sudokoup');
      messager.print("That's awesome!");
      messager.print("I know that's right!");
      var paragraphs = $("#pane p");
      expect(paragraphs.length).toEqual(2);
      expect(paragraphs.first().text()).toEqual("That's awesome!");
      expect(paragraphs.last().text()).toEqual("I know that's right!");
    });
  });

});