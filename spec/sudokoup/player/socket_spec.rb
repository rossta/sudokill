require 'spec_helper'

describe Sudokoup::Player::Socket do
  
  describe "enter_game" do
    before(:each) do
      @player = Sudokoup::Player::Socket.new({})
    end
    it "should assign given number" do
      @player.enter_game 1
      @player.number.should == 1
    end
    
    it "should set state to playing" do
      @player.enter_game 1
      @player.playing?.should be_true
    end
  end
end
