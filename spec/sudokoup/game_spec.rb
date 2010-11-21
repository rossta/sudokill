require 'spec_helper'

describe Sudokoup::Game do
  before(:each) do
    @game = Sudokoup::Game.new
  end
  describe "initialize" do
    it "should build a board" do
      board = mock(Sudokoup::Board)
      Sudokoup::Board.should_receive(:new).and_return(board)
      board.should_receive(:build)
      game = Sudokoup::Game.new
      game.board.should == board
    end
  end

  describe "reset" do
    it "should rebuild board" do
      game = Sudokoup::Game.new
      board = mock(Sudokoup::Board)
      Sudokoup::Board.should_receive(:new).and_return(board)
      board.should_receive(:build)
      game.reset
      game.board.should == board
    end
  end

  describe "play!" do
    it "should raise warning if not ready" do
      lambda { subject.play! }.should raise_error
    end
    before(:each) do
      @game = Sudokoup::Game.new
      @player_1 = mock(Sudokoup::Player::Socket, :enter_game => nil)
      @player_2 = mock(Sudokoup::Player::Socket, :enter_game => nil)
      @game.join_game @player_1
      @game.join_game @player_2
    end
    it "should set state to in_progress" do
      @game.play!
      @game.in_progress?.should be_true
    end

    it "should enter game and assign player numbers" do
      @player_1.should_receive(:enter_game).with(1)
      @player_2.should_receive(:enter_game).with(2)
      @game.play!
    end

  end

  describe "request_player_move" do
    before(:each) do
      @player_1 = mock(Sudokoup::Player::Socket, :name => "Player 1")
      @player_2 = mock(Sudokoup::Player::Socket, :name => "Player 2")
      @board = mock(Sudokoup::Board, :add_move => true, :violated? => false)
      @game.board = @board
      @game.players << @player_1
      @game.players << @player_2
    end
    it "should verify player's turn" do
      @player_1.should_receive(:has_turn?).and_return(true)
      @game.request_player_move(@player_1, "1 2 3")
    end
    it "should verify player is in game" do
      @non_player = mock(Sudokoup::Player::Socket, :name => "Party crasher")
      @non_player.should_not_receive(:has_turn?)
      @board.should_not_receive(:add_move)
      @game.request_player_move(@non_player, "1 2 3").should == [:reject, "Not in the game, Party crasher"]
    end
    describe "player's turn" do
      before(:each) do
        @player_1.stub!(:has_turn? => true)
      end
      it "should add_move to board if available?" do
        @board.should_receive(:add_move).with(1, 2, 3).and_return(true)
        @game.request_player_move(@player_1, "1 2 3")
      end
      it "should return success message if move successful" do
        @game.request_player_move(@player_1, "1 2 3").should == [:ok, "Player 1 played: 1 2 3"]
      end
      it "should send reject message to player_1 if move is an error" do
        @board.stub!(:add_move).and_return(false)
        @game.request_player_move(@player_1, "0 0 0").should == [:reject, "Illegal move. Player 1 cannot play 0 0 0"]
      end
      describe "game ends on player move" do
        it "should notify players if player 1 move results in board violation" do
          @board.stub!(:add_move).and_return(false)
          @board.should_receive(:violated?).and_return(true)
          @game.request_player_move(@player_1, "1 2 3").should == [:violation, "Player 1 played: 1 2 3 and violated the constraints!"]
        end
        it "should notify players if player 2 move results in board violation" do
          @board.stub!(:add_move).and_return(false)
          @player_2.stub!(:has_turn?).and_return(true)
          @board.should_receive(:violated?).and_return(true)
          @game.request_player_move(@player_2, "1 2 3").should == [:violation, "Player 2 played: 1 2 3 and violated the constraints!"]
        end
      end
    end
    describe "not player's turn" do
      before(:each) do
        @player_1.stub!(:has_turn? => false)
      end
      it "should not update the game board" do
        @board.should_not_receive(:add_move)
      end
      it "should not send update to game display" do
        @game.request_player_move(@player_1, "1 2 3").should == [:reject, "Wait your turn, Player 1"]
      end
    end
  end

  describe "add_move" do
    before(:each) do
      @board = mock(Sudokoup::Board, :add_move => true)
      @game.board = @board
    end
    describe "legal_move" do
      it "should return true" do
        @game.add_move(4, 5, 9).should be_true
      end
      it "should add move to board" do
        @board.should_receive(:add_move)
        @game.add_move(4, 5, 9)
      end
    end
    describe "illegal_move" do
      before(:each) do
        @board.stub!(:add_move).and_return(false)
      end
      it "should return true" do
        @game.add_move(4, 5, 9).should be_false
      end
      it "should add move to board" do
        @board.should_receive(:add_move)
        @game.add_move(4, 5, 9)
      end
    end
  end
  describe "join_game" do
    it "should return true if successful, false if not" do
      @game.join_game(:player_1).should be_true
      @game.join_game(:player_2).should be_true
      @game.join_game(:player_3).should be_false
    end
    it "should add to players" do
      @game.players.should be_empty
      @game.join_game(:player_1)
      @game.players.size.should == 1
      @game.players.should include(:player_1)
      @game.join_game(:player_2)
      @game.players.size.should == 2
      @game.players.should include(:player_2)
      @game.join_game(:player_3)
      @game.players.size.should == 2
      @game.players.should_not include(:player_3)
    end
    it "should change state from waiting to ready when full" do
      @game.waiting?.should be_true
      @game.ready?.should be_false

      @game.join_game(:player_1)
      @game.waiting?.should be_true
      @game.ready?.should be_false

      @game.join_game(:player_2)
      @game.waiting?.should be_false
      @game.ready?.should be_true
    end
  end
  describe "states" do
    describe "available?" do
      it "should be true if waiting and player size < num players" do
        @game.state = :waiting
        @game.available?.should be_true
      end
      it "should be false if not waiting" do
        @game.state = :ready
        @game.available?.should be_false
      end
      it "should be false if player size == num players" do
        @game.join_game(:player_1)
        @game.join_game(:player_2)
        @game.available?.should be_false
      end
    end
    describe "in_progress?" do
      it "should be false if game state != :in_progress" do
        @game.state.should_not == :in_progress
        @game.in_progress?.should be_false
      end
      it "should return true if game state == :in_progress" do
        @game.state = :in_progress
        @game.in_progress?.should be_true
      end
    end
    describe "waiting?" do
      it "should be false if game state != :waiting" do
        @game.state = :in_progress
        @game.waiting?.should be_false
      end
      it "should return true if game state == :waiting" do
        @game.waiting?.should be_true
      end
    end
    describe "ready?" do
      it "should be false if game state != :ready" do
        @game.ready?.should be_false
      end
      it "should return true if game state == :ready" do
        @game.state = :ready
        @game.ready?.should be_true
      end
    end
    describe "over?" do
      it "should be false if game state != :ready" do
        @game.over?.should be_false
      end
      it "should return true if game state == :ready" do
        @game.state = :over
        @game.over?.should be_true
      end
    end
  end

  describe "status" do
    it "should return 'Waiting for more players' if waiting" do
      @game.status.should == 'Game waiting for more players'
    end
  end

  describe "current_player" do
    it "should return player with status of :has_turn" do
      @player_1 = mock(Sudokoup::Player::Socket, :has_turn? => false)
      @player_2 = mock(Sudokoup::Player::Socket, :has_turn? => true)
      @game.join_game @player_1
      @game.join_game @player_2
      @game.current_player.should == @player_2
    end
  end
end
