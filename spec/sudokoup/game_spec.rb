require 'spec_helper'

describe Sudokoup::Game do
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
  
  describe "player_move" do
    before(:each) do
      @game = Sudokoup::Game.new
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
end
