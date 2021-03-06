describe("Sudokill.ScoreBoard", function() {
  var createScoreBoard = function() {
    return new Sudokill.ScoreBoard("score_board", "#sudokill");
  };

  beforeEach(fixture);
  afterEach(removeFixture);

  describe("constructor", function() {
    it("should append div with given dom id to game container", function() {
      var board = new Sudokill.ScoreBoard("score_board", "#sudokill");
      var $game = $("#sudokill");
      var $board = $("#score_board");
      expect($game).toHaveSelector("#score_board");

      $board.text("Hello World");
      expect($board).toBeVisible();
    });
  });

  describe("build", function() {
    it("should add #score and #queue sections", function() {
      var board = createScoreBoard();
      var $board;
      board.build();
      $board = $("#score_board");
      expect($board).toHaveSelector("#score");
      expect($board).toHaveSelector("#queue");
    });
    it("should add column headers for #score and #queue", function() {
      var board = createScoreBoard();
      var $score, $queue;
      board.build();
      $score = $("#score");
      $queue = $("#queue");
      expect($score.find(".header").text()).toEqual("Now playing");
      expect($queue.find(".header").text()).toEqual("On deck");
    });
  });

  describe("updateScore", function() {
    it("should display player json data in #score", function() {
      var board = createScoreBoard().build();
      var $score = $("#score");
      var players = [
        {
          number: 1,
          current_time: 14,
          max_time: 120,
          name: 'Player 1',
          moves: 3,
          has_turn: false
        },
        {
          number: 2,
          current_time: 8,
          max_time: 120,
          name: 'Player 2',
          moves: 2,
          has_turn: true
        }
      ];
      var $player1, $player2;

      board.updateScore(players);
      $player1 = $score.find('.player').first();
      $player2 = $score.find('.player').last();

      expect($score.find(".player")).toHaveLength(2);

      expect($player1.find(".name").text()).toEqual("Player 1");
      expect($player1.find(".time"  ).text()).toEqual("Time: " + (120 - 14));
      expect($player1.find(".moves").text()).toEqual("Moves: 3");
      expect($player1.hasClass("has_turn")).toBeFalsy();
      
      expect($player2.find(".name").text()).toEqual("Player 2");
      expect($player2.find(".time").text()).toEqual("Time: " + (120 - 8));
      expect($player2.hasClass("has_turn")).toBeTruthy();
    });

    it("should add latecomers to #score", function() {
      var board = createScoreBoard().build();
      var $score = $("#score");
      var players = [
        {
          number: 1,
          current_time: 14,
          max_time: 120,
          name: 'Player 1',
          moves: 3,
          has_turn: true
        }
      ];

      board.updateScore(players);
      $player1 = $score.find('.player').first();

      expect($score.find(".player")).toHaveLength(1);

      expect($player1.find(".name").text()).toEqual("Player 1");
      expect($player1.find(".time").text()).toEqual("Time: " + (120 - 14));
      expect($player1.find(".moves").text()).toEqual("Moves: 3");
      expect($player1.hasClass("has_turn")).toBeTruthy();
      
      players = [
        {
          number: 1,
          current_time: 16,
          max_time: 120,
          name: 'Player 1',
          moves: 3,
          has_turn: false
        },
        {
          number: 2,
          current_time: 8,
          max_time: 120,
          name: 'Player 2',
          moves: 2,
          has_turn: true
        }
      ];
      board.updateScore(players);
      $player1 = $score.find('.player').first();
      $player2 = $score.find('.player').last();

      expect($score.find(".player")).toHaveLength(2);

      expect($player1.find(".name").text()).toEqual("Player 1");
      expect($player1.find(".time").text()).toEqual("Time: " + (120 - 16));
      expect($player1.find(".moves").text()).toEqual("Moves: 3");
      expect($player1.hasClass("has_turn")).toBeFalsy();
      
      expect($player2.find(".name").text()).toEqual("Player 2");
      expect($player2.find(".time").text()).toEqual("Time: " + (120 - 8));
      expect($player2.hasClass("has_turn")).toBeTruthy();
    });
  });
  
  describe("updateQueue", function() {
    it("should display player json data in #queue", function() {
      var board = createScoreBoard().build();
      var $queue = $("#queue");
      var players = [
        {
          name: 'Player 1'
        },
        {
          name: 'Player 2'
        }
      ];
      var $player1, $player2;

      board.updateQueue(players);
      $player1 = $queue.find('.player').first();
      $player2 = $queue.find('.player').last();

      expect($queue.find(".player")).toHaveLength(2);
      expect($player1.find(".name").text()).toEqual("Player 1");
      expect($player2.find(".name").text()).toEqual("Player 2");
    });
  });
});