require 'spec_helper'

describe Sudokill::Move do
  describe "initialize" do
    it "should have row, col, val" do
      move = Sudokill::Move.new(4, 5, 6)
      move.row.should == 4
      move.col.should == 5
      move.val.should == 6
    end
  end
  
  describe "to_json" do
    it "should return {row:row,col:col,val:val}" do
      move = Sudokill::Move.new(4, 5, 6)
      move.to_json.should == "[4, 5, 6]"
    end
  end
  
  describe "self.build" do
    it "should return new move with player number" do
      move = Sudokill::Move.build("1 2 3", 1)
      move.row.should == 1
      move.col.should == 2
      move.val.should == 3
      move.num.should == 1
    end
  end
end
