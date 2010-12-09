require 'spec_helper'

describe Sudocoup::Board do

  before(:each) do
    @pipe = "|"
    @rows = <<-TXT
7 0 5 0 0 0 2 9 4
0 0 1 2 0 6 0 0 0
0 0 0 0 0 0 0 0 7
9 0 4 5 0 0 0 2 0
0 0 7 3 6 2 1 0 0
0 2 0 0 0 1 7 0 8
1 0 0 0 9 0 0 0 0
0 0 0 7 0 5 9 0 0
5 3 9 0 0 0 8 0 2
TXT
  end

  describe "build_from_string" do

    it "should load CONFIG_1 rows" do
      board = Sudocoup::Board.new
      board.build_from_string(@rows)
      values = @rows.split("\n").map(&:split)
      values.each_with_index do |row, i|
        row.each_with_index do |value, j|
          board[i][j].should == value.to_i
        end
      end

    end

  end

  describe "formatting" do
    before(:each) do
      @board = Sudocoup::Board.new
      @board.build_from_string(@rows)
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
7 0 5 0 0 0 2 9 4|0 0 1 2 0 6 0 0 0|0 0 0 0 0 0 0 0 7|9 0 4 5 0 0 0 2 0|0 0 7 3 6 2 1 0 0|0 2 0 0 0 1 7 0 8|1 0 0 0 9 0 0 0 0|0 0 0 7 0 5 9 0 0|5 3 9 0 0 0 8 0 2
MSG
        @board.to_msg.should == msg.chomp
      end
      it "should be parseable with split" do
        rows = @board.to_msg.split(@pipe).map { |row| row.split(" ").map(&:to_i) }
        rows.first.should == [7, 0, 5, 0, 0, 0, 2, 9, 4]
      end
    end
  end

  describe "add_move" do
    before(:each) do
      @board = Sudocoup::Board.new
      @board.build
    end
    describe "first move, space unoccupied" do
      it "should return true" do
        @board.add_move(1, 1, 9).should be_true
      end
      it "should add to rows" do
        @board.rows[1][1].should be_zero
        @board.add_move(1, 1, 9).should be_true
        @board.rows[1][1].should == 9
      end
      it "should not report an error" do
        @board.add_move(1, 1, 9)
        @board.error.should be_nil
      end
    end
    describe "space occupied with value" do
      it "should return false" do
        @board.add_move(0, 0, 9).should be_false
      end
      it "should not add to rows if existing value" do
        @board.rows[0][0].should == 7
        @board.add_move(0, 0, 9).should be_false
        @board.rows[0][0].should == 7
      end
      it "should report error" do
        @board.rows[0][0].should == 7
        @board.add_move(0, 0, 9).should be_false
        @board.error.should == "Space occupied error: 0 0 is occupied"
      end
    end
    describe "out of range" do
      it "should return false" do
        @board.add_move(9, 9, 9).should be_false
      end
      it "should report error" do
        @board.add_move(9, 9, 9)
        @board.error.should == "Out of range error: 9 9 is not a valid space"
      end
      it "should clear error after successful move" do
        @board.add_move(9, 9, 9)
        @board.add_move(1, 1, 9)
        @board.error.should be_nil
      end
    end
    describe "non-sudoku value" do
      it "should return false" do
        @board.add_move(1, 1, 10).should be_false
      end
      it "should report error" do
        @board.add_move(1, 1, 10)
        @board.error.should == "Bad value error: 10 is not a valid Sudoku value"
      end
    end
    describe "subsequent move" do
      describe "legal move: same col" do
        before(:each) do
          @board.add_move(0, 4, 3) # first move: legal
        end
        it "should return true" do
          @board.add_move(1, 4, 7).should be_true
        end
        it "should not report error" do
          @board.add_move(1, 4, 7)
          @board.error.should be_nil
        end
      end
      describe "legal move: same row" do
        before(:each) do
          @board.add_move(0, 4, 3) # first move: legal
        end
        it "should return true" do
          @board.add_move(0, 5, 8).should be_true
        end
        it "should not report error" do
          @board.add_move(0, 5, 8)
          @board.error.should be_nil
        end
      end
      describe "legal move: new row when row and column full" do
        # Start
        # 7 0 5 0 0 0 2 9 4
        # 0 0 1 2 0 6 0 0 0
        # 0 0 0 0 0 0 0 0 7
        # 9 0 4 5 0 0 0 2 0
        # 0 0 7 3 6 2 1 0 0
        # 0 2 0 0 0 1 7 0 8
        # 1 0 0 0 9 0 0 0 0
        # 0 0 0 7 0 5 9 0 0
        # 5 3 9 0 0 0 8 0 2
        
        # Finish
        # 7 6 5 1 3 8 2 9 4
        # 4 9 1 2 7 6 5 8 3
        # 2 8 3 4 5 9 6 1 7
        # 9 1 4 5 8 7 3 2 6
        # 8 5 7 3 6 2 1 4 9
        # 3 2 6 9 4 1 7 5 8
        # 1 7 2 8 9 3 4 6 5
        # 6 4 8 7 2 5 9 3 1
        # 5 3 9 6 1 4 8 7 2

        # Start
        # row 1: 0 0 1 2 0 6 0 0 0
        # col 1: 0 0 0 0 0 2 0 0 3
        
        it "should return true" do
          # fill in row 1 except col 1
          @board[1][0] = 4
          @board[1][4] = 7
          @board[1][6] = 5
          @board[1][7] = 8
          @board[1][8] = 3

          # fill in col 1 except row 1
          @board.add_move(0, 1, 6).should be_true
          @board.add_move(2, 1, 8).should be_true
          @board.add_move(3, 1, 1).should be_true
          @board.add_move(4, 1, 5).should be_true
          @board.add_move(6, 1, 7).should be_true
          @board.add_move(7, 1, 4).should be_true
          
          # fill in final spot in row 1 col 1
          @board.add_move(1, 1, 9).should be_true
          
          # new col and row move
          @board.add_move(2, 2, 3).should be_true
          @board.error.should be_nil
        end
      end
      describe "illegal move: not same column or row" do
        before(:each) do
          @board.add_move(0, 4, 8) # first move: legal
        end
        it "should return false" do
          @board.add_move(1, 1, 5).should be_false
        end
        it "should report error" do
          @board.add_move(1, 1, 5)
          @board.error.should == "Required placement error: must play either row 0 or col 4"
        end
      end
      describe "illegal move: violation in row" do
        before(:each) do
          @board.add_move(0, 4, 3) # first move: legal
        end
        it "should return false" do
          @board.add_move(0, 5, 3).should be_false
        end
        it "should report error" do
          @board.add_move(0, 5, 3)
          @board.error.should == "Constraint violation error: there is already a 3 in row 0!"
        end
        it "should mark board violated" do
          @board.add_move(0, 5, 3)
          @board.violated?.should be_true
        end
      end
      describe "illegal move: violation in col" do
        before(:each) do
          @board.add_move(0, 4, 3) # first move: legal
        end
        it "should return false" do
          @board.add_move(1, 4, 3).should be_false
        end
        it "should report error" do
          @board.add_move(1, 4, 3)
          @board.error.should == "Constraint violation error: there is already a 3 in col 4!"
        end
        it "should mark board violated" do
          @board.add_move(1, 4, 3)
          @board.violated?.should be_true
        end
      end
      describe "illegal move: violation in section" do
        before(:each) do
          @board.add_move(0, 3, 8) # first move: legal
          @board.add_move(0, 4, 3) # first move: legal
        end
        it "should return false" do
          @board.add_move(1, 4, 8).should be_false # already a 6 at 1, 5
        end
        it "should report error" do
          @board.add_move(1, 4, 8)
          @board.error.should == "Constraint violation error: there is already a 8 in section 1!"
        end
        it "should mark board violated" do
          @board.add_move(1, 4, 8)
          @board.violated?.should be_true
        end
      end
    end

  end

  describe "available?" do
    before(:each) do
      @board = Sudocoup::Board.new
      @board.build
    end
    describe "valid value" do
      it "should return true if no previous value" do
        @board.rows[1][1].should be_zero
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
