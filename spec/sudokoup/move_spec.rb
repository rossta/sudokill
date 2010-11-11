require 'spec_helper'

describe Sudokoup::Move do
  describe "initialize" do
    it "should have x, y, value" do
      move = Sudokoup::Move.new(4, 5, 6)
      move.x.should == 4
      move.y.should == 5
      move.value.should == 6
    end
  end
  
  describe "to_json" do
    it "should return {x:x,y:y,value:value}" do
      move = Sudokoup::Move.new(4, 5, 6)
      move.to_json.should == "[4, 5, 6]"
    end
  end
end
