require 'spec_helper'

describe Sudocoup::Move do
  describe "initialize" do
    it "should have row, col, val" do
      move = Sudocoup::Move.new(4, 5, 6)
      move.row.should == 4
      move.col.should == 5
      move.val.should == 6
    end
  end
  
  describe "to_json" do
    it "should return {row:row,col:col,val:val}" do
      move = Sudocoup::Move.new(4, 5, 6)
      move.to_json.should == "[4, 5, 6]"
    end
  end
end
