describe("Sudocoup.GameBoard", function() {
  var createGameBoard = function() {
    return new Sudocoup.GameBoard("game_board", "#sudocoup");
  },

  board;

  beforeEach(fixture);
  afterEach(removeFixture);

  describe("constructor", function() {
    it("should assign instance variables", function() {
      board = new Sudocoup.GameBoard("game_board", "#sudocoup");
      expect(board.hilite).toEqual("#333333");
      expect(board.black).toEqual("#000000");
      expect(board.transparent).toEqual("transparent");
      expect(board.domId).toEqual("game_board");
      expect(board.$selector.selector).toEqual("#game_board");
      expect(board.dim).toEqual(50);
      expect(board.numberSquares).toEqual(jasmine.any(Array));
      expect(board.backgroundSquares).toEqual(jasmine.any(Array));
      expect(board.$sudocoup.selector).toEqual("#sudocoup");
      expect(board.valids).toEqual([1,2,3,4,5,6,7,8,9]);
    });
    it("should append #game_board to container", function() {
      board = new Sudocoup.GameBoard("game_board", "#sudocoup");
      var $sudocoup = $("#sudocoup");
      expect($sudocoup).toHaveSelector("#game_board");
    });
    it("should build array of 9x9 rows for number squares and text squares", function() {
      board = new Sudocoup.GameBoard("game_board", "#sudocoup");
      expect(board.numberSquares).toHaveLength(9);
      for(i=0;i<9;i++) {
        expect(board.numberSquares[i]).toHaveLength(9);
        expect(board.backgroundSquares[i]).toHaveLength(9);
      }
    });
    it("should append form for row, col, val input", function() {
      board = new Sudocoup.GameBoard("game_board", "#sudocoup");
      var $form = $("form.game_board");
      expect($form).toHaveSelector("input[name*=row]");
      expect($form).toHaveSelector("input[name*=col]");
      expect($form).toHaveSelector("input[name*=val]");
    });
  });

  describe("submit", function() {
    beforeEach(function() {
      board = createGameBoard();
    });
    it("should trigger send message with 'MOVE|row col val' from inputs if valid", function() {
      $("input[name*=row]").val("1");
      $("input[name*=col]").val("2");
      $("input[name*=val]").val("3");
      spyOn(board.$sudocoup, "trigger");
      board.$form.submit();
      expect(board.$sudocoup.trigger).toHaveBeenCalledWith("send_message", "MOVE|1 2 3");
    });
    it("should not trigger send message if value not valid", function() {
      $("input[name*=row]").val("1");
      $("input[name*=col]").val("2");
      $("input[name*=val]").val("0");
      spyOn(board.$sudocoup, "trigger");
      board.$form.submit();
      expect(board.$sudocoup.trigger).not.toHaveBeenCalled();
    });
  });

  describe("raphael", function() {
    beforeEach(function() {
      board = createGameBoard();
    });
    it("should return an instance of Raphael", function() {
      expect(board.raphael()).toEqual(jasmine.any(Raphael));
    });
    it("should clear raphael if already exists", function() {
      var r = board.raphael();
      spyOn(r, "clear");
      board.raphael();
      expect(r.clear).toHaveBeenCalled();
    });
    it("should return the same raphael if already exists", function() {
      var r1 = board.raphael();
      var r2 = board.raphael();
      expect(r1).toEqual(r2);
    });
  });
  describe("isValid", function() {
    beforeEach(function() {
      board = createGameBoard();
    });
    it("should return true if given value is int 1 to 9", function() {
      expect(board.isValid(1)).toBeTruthy();
      expect(board.isValid(2)).toBeTruthy();
      expect(board.isValid(3)).toBeTruthy();
      expect(board.isValid(4)).toBeTruthy();
      expect(board.isValid(5)).toBeTruthy();
      expect(board.isValid(6)).toBeTruthy();
      expect(board.isValid(7)).toBeTruthy();
      expect(board.isValid(8)).toBeTruthy();
      expect(board.isValid(9)).toBeTruthy();
    });
    it("should return true if given value is string int 1 to 9", function() {
      expect(board.isValid("1")).toBeTruthy();
      expect(board.isValid("2")).toBeTruthy();
      expect(board.isValid("3")).toBeTruthy();
      expect(board.isValid("4")).toBeTruthy();
      expect(board.isValid("5")).toBeTruthy();
      expect(board.isValid("6")).toBeTruthy();
      expect(board.isValid("7")).toBeTruthy();
      expect(board.isValid("8")).toBeTruthy();
      expect(board.isValid("9")).toBeTruthy();
    });
    it("should return false otherwise", function() {
      expect(board.isValid(0)).toBeFalsy();
      expect(board.isValid("0")).toBeFalsy();
      expect(board.isValid("1.5")).toBeFalsy();
      expect(board.isValid(1.5)).toBeFalsy();
      expect(board.isValid("8.1")).toBeFalsy();
      expect(board.isValid(8.1)).toBeFalsy();
      expect(board.isValid("15")).toBeFalsy();
      expect(board.isValid(15)).toBeFalsy();
      expect(board.isValid("a")).toBeFalsy();
      expect(board.isValid("foo")).toBeFalsy();
    });
  });

  describe("update", function() {

  });

  describe("update", function() {

  });

  describe("build", function() {

  });
});