require 'spec_helper'

describe Sudokoup::Board do

  describe "build_from_string" do

    it "should load CONFIG_1 config" do
      board = Sudokoup::Board.new
      board.build_from_string(Sudokoup::CONFIG_1)
      values = Sudokoup::CONFIG_1.split("\n").map(&:split)
      values.each_with_index do |row, i|
        row.each_with_index do |value, j|
          board[i][j].should == value.to_i
        end
      end
    end
  end

  describe "formatting" do
    before(:each) do
      @board = Sudokoup::Board.new
      @board.build_from_string(Sudokoup::CONFIG_1)
    end
    describe "to_json" do
      it "should return stringified json version of board" do
      json = <<-JSON
[[7, 0, 5, 0, 0, 0, 2, 9, 4], [0, 0, 1, 2, 0, 6, 0, 0, 0], [0, 0, 0, 0, 0, 0, 0, 0, 7], [9, 0, 4, 5, 0, 0, 0, 2, 0], [0, 0, 7, 3, 6, 2, 1, 0, 0], [0, 2, 0, 0, 0, 1, 7, 0, 8], [1, 0, 0, 0, 9, 0, 0, 0, 0], [0, 0, 0, 7, 0, 5, 9, 0, 0], [5, 3, 9, 0, 0, 0, 8, 0, 2]]
JSON
        @board.to_json.should == json.chomp
      end
    end
  
    describe "to_msg" do
      it "should return space delimited values, pipe joined rows" do
        msg = <<-MSG
7 0 5 0 0 0 2 9 4 | 0 0 1 2 0 6 0 0 0 | 0 0 0 0 0 0 0 0 7 | 9 0 4 5 0 0 0 2 0 | 0 0 7 3 6 2 1 0 0 | 0 2 0 0 0 1 7 0 8 | 1 0 0 0 9 0 0 0 0 | 0 0 0 7 0 5 9 0 0 | 5 3 9 0 0 0 8 0 2
MSG
        @board.to_msg.should == msg.chomp
      end
      it "should be parseable with split" do
        @board.to_msg.split(" | ").map { |row| row.split(" ") }
      end
    end
  end
  
  describe "add_move" do
    before(:each) do
      @board = Sudokoup::Board.new
      @board.build
    end
    describe "no previous value" do
      it "should return true" do
        @board.add_move(1, 1, 9).should be_true
      end
      it "should add to config" do
        @board.config[1][1].should be_zero
        @board.add_move(1, 1, 9).should be_true
        @board.config[1][1].should == 9
      end
    end
    describe "previous value" do
      it "should return false" do
        @board.add_move(0, 0, 9).should be_false
      end
      it "should not add to config if existing value" do
        @board.config[0][0].should == 7
        @board.add_move(0, 0, 9).should be_false
        @board.config[0][0].should == 7
      end
    end
    describe "out of range" do
      it "should return false" do
        @board.add_move(9, 9, 9).should be_false
      end
    end
    describe "non-sudoku value" do
      it "should return false" do
        @board.add_move(1, 1, 10).should be_false
      end
    end
  end
  
  describe "available?" do
    before(:each) do
      @board = Sudokoup::Board.new
      @board.build
    end
    describe "valid value" do
      it "should return true if no previous value" do
        @board.config[1][1].should be_zero
        @board.available? 1, 1, 9
      end
    end
    describe "invalid value" do
      it "should return true if no previous value" do
        @board.available? 1, 1, 10
      end
    end
  end
end
