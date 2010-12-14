require 'spec_helper'

describe Sudocoup::Game do
  before(:each) do
    @game = Sudocoup::Game.new
  end
  describe "initialize" do
    it "should build a board" do
      board = mock(Sudocoup::Board)
      Sudocoup::Board.should_receive(:new).and_return(board)
      board.should_receive(:build)
      game = Sudocoup::Game.new
      game.board.should == board
    end
  end

  describe "reset" do
    it "should rebuild board" do
      game = Sudocoup::Game.new
      board = mock(Sudocoup::Board)
      Sudocoup::Board.should_receive(:new).and_return(board)
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
      @game = Sudocoup::Game.new
      @player_1 = mock(Sudocoup::Client::Socket, :enter_game => nil)
      @player_2 = mock(Sudocoup::Client::Socket, :enter_game => nil)
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

  describe "add_player_move" do
    before(:each) do
      @player_1 = mock(Sudocoup::Client::Socket, :name => "Player 1", :stop_timer! => nil, :add_move => nil)
      @player_2 = mock(Sudocoup::Client::Socket, :name => "Player 2", :stop_timer! => nil, :add_move => nil)
      @board = mock(Sudocoup::Board, :add_move => true, :violated? => false, :error => "board error")
      @game.board = @board
      @game.players << @player_1
      @game.players << @player_2
    end
    it "should verify player's turn" do
      @player_1.should_receive(:has_turn?).and_return(true)
      @game.add_player_move(@player_1, "1 2 3")
    end
    it "should verify player is in game" do
      @non_player = mock(Sudocoup::Client::Socket, :name => "Party crasher")
      @non_player.should_not_receive(:has_turn?)
      @board.should_not_receive(:add_move)
      @game.add_player_move(@non_player, "1 2 3").should == [:reject, "1 Not in the game, Party crasher"]
    end
    describe "player's turn" do
      before(:each) do
        @player_1.stub!(:has_turn? => true)
      end
      it "should add_move to board if available?" do
        @board.should_receive(:add_move).with(1, 2, 3).and_return(true)
        @game.add_player_move(@player_1, "1 2 3")
      end
      it "should stop player timer" do
        @player_1.should_receive(:stop_timer!)
        @game.add_player_move(@player_1, "1 2 3")
      end
      it "should add to players list of moves" do
        @player_1.should_receive(:add_move).with(1, 2, 3)
        @game.add_player_move(@player_1, "1 2 3")
      end
      it "should return success message if move successful" do
        @game.add_player_move(@player_1, "1 2 3").should == [:ok, "Player 1 played: 1 2 3"]
      end
      it "should send reject message to player_1 if move is an error" do
        @board.stub!(:add_move).and_return(false)
        @game.add_player_move(@player_1, "0 0 0").should == [:violation, "Player 2 WINS! Player 1 played 0 0 0: board error"]
      end
      describe "game ends on player move" do
        it "should notify players if player 1 move results in board violation" do
          @board.stub!(:add_move).and_return(false)
          @game.add_player_move(@player_1, "1 2 3").should == [:violation, "Player 2 WINS! Player 1 played 1 2 3: board error"]
        end
        it "should notify players if player 2 move results in board violation" do
          @board.stub!(:add_move).and_return(false)
          @player_1.stub!(:has_turn?).and_return(false)
          @player_2.stub!(:has_turn?).and_return(true)
          @game.add_player_move(@player_2, "1 2 3").should == [:violation, "Player 1 WINS! Player 2 played 1 2 3: board error"]
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
        @game.add_player_move(@player_1, "1 2 3").should == [:reject, "2 Wait your turn, Player 1"]
      end
    end
  end

  describe "add_move_to_board" do
    before(:each) do
      @board = mock(Sudocoup::Board, :add_move => true)
      @game.board = @board
    end
    describe "legal_move" do
      it "should return true" do
        @game.add_move_to_board(4, 5, 9).should be_true
      end
      it "should add move to board" do
        @board.should_receive(:add_move)
        @game.add_move_to_board(4, 5, 9)
      end
    end
    describe "illegal_move" do
      before(:each) do
        @board.stub!(:add_move).and_return(false)
      end
      it "should return true" do
        @game.add_move_to_board(4, 5, 9).should be_false
      end
      it "should add move to board" do
        @board.should_receive(:add_move)
        @game.add_move_to_board(4, 5, 9)
      end
    end
  end
  describe "join_game" do
    describe "game size is 2" do
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
    describe "game size is 3" do
      before(:each) do
        @game.size = 3
      end
      it "should return true if successful, false if not" do
        @game.join_game(:player_1).should be_true
        @game.join_game(:player_2).should be_true
        @game.join_game(:player_3).should be_true
        @game.join_game(:player_4).should be_false
      end
      it "should add to players" do
        @game.join_game(:player_1)
        @game.join_game(:player_2)
        @game.join_game(:player_3)
        @game.players.size.should == 3
        @game.players.should include(:player_3)
        @game.join_game(:player_4)
        @game.players.size.should == 3
        @game.players.should_not include(:player_4)
      end
      it "should change state from waiting to ready when full" do
        @game.join_game(:player_1)
        @game.join_game(:player_2)
        @game.waiting?.should be_true
        @game.ready?.should be_false
        @game.join_game(:player_3)
        @game.waiting?.should be_false
        @game.ready?.should be_true
      end
    end
  end
  describe "states" do
    describe "has_player?" do
      before(:each) do
        @game.join_game :player_1
      end
      it "should return true if has player" do
        @game.has_player?(:player_1).should be_true
      end
      it "should return true if has player" do
        @game.has_player?(:player_2).should be_false
      end
    end
    describe "available?" do
      it "should be true if waiting and player size < num players" do
        @game.waiting!
        @game.available?.should be_true
      end
      it "should be false if not waiting" do
        @game.ready!
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
        @game.sudocoup_state.should_not == :in_progress
        @game.in_progress?.should be_false
      end
      it "should return true if game state == :in_progress" do
        @game.sudocoup_state = :in_progress
        @game.in_progress?.should be_true
      end
    end
    describe "waiting?" do
      it "should be false if game state != :waiting" do
        @game.sudocoup_state = :in_progress
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
        @game.sudocoup_state = :ready
        @game.ready?.should be_true
      end
    end
    describe "over?" do
      it "should be false if game state != :ready" do
        @game.over?.should be_false
      end
      it "should return true if game state == :ready" do
        @game.sudocoup_state = :over
        @game.over?.should be_true
      end
    end
  end

  describe "status" do
    it "should return 'Waiting for more players' if waiting" do
      @game.status.should == 'Waiting for more players'
    end
  end

  describe "players" do
    before(:each) do
      @player_1 = Sudocoup::Client::Socket.new({})
      @player_2 = Sudocoup::Client::Socket.new({})
      @player_1.stub!(:send_data)
      @player_2.stub!(:send_data)
      @game.join_game @player_1
      @game.join_game @player_2
    end
    describe "current_player" do
      it "should return player with status of :has_turn" do
        @player_2.has_turn!
        @game.current_player.should == @player_2
      end
    end

    describe "next_player" do
      it "should return player after current player in list" do
        @player_1.has_turn!
        @game.next_player.should == @player_2
      end
      it "should return player at start of list if at end of list" do
        @player_2.has_turn!
        @game.next_player.should == @player_1
      end
      it "should return first player if current_player is nil" do
        @game.next_player.should == @player_1
      end
    end

    describe "previous_player" do
      it "should return player before player in list" do
        @player_2.has_turn!
        @game.previous_player.should == @player_1
      end
      it "should return player at end of list if at start of list" do
        @player_1.has_turn!
        @game.previous_player.should == @player_2
      end
      it "should return nil if current_player is nil" do
        @game.previous_player.should be_nil
      end
    end

    describe "next_player!" do
      it "should select first player if no current_player" do
        @game.current_player.should be_nil
        @game.next_player!
        @game.current_player.should == @player_1
        @game.players.select { |p| p.has_turn? }.size.should == 1
      end
      it "should result in next player being current player" do
        @player_1.has_turn!
        @game.current_player.should == @player_1
        @game.next_player!
        @game.current_player.should == @player_2
        @game.players.select { |p| p.has_turn? }.size.should == 1
      end
    end

    describe "next_player_request" do
      before(:each) do
        @player_1.has_turn!
      end
      it "should set next player as current player" do
        @game.next_player_request
        @game.current_player.should == @player_2
      end
      it "should send given message to next player" do
        @player_2.should_receive(:send_data).with("ADD|1 2 3 4 5 6 7 8 9\r\n")
        @game.next_player_request do |player|
          player.send("ADD|1 2 3 4 5 6 7 8 9")
        end
      end
      it "should start player_2 timer" do
        @player_2.should_receive(:start_timer!)
        @game.next_player_request
      end
    end
  end
end
