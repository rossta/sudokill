require 'spec_helper'

describe Sudokoup::Player::Socket do
  before(:each) do
    @player = Sudokoup::Player::Socket.new({})
  end

  describe "enter_game" do
    it "should assign given number" do
      @player.enter_game 1
      @player.number.should == 1
    end

    it "should set state to playing" do
      @player.enter_game 1
      @player.playing?.should be_true
    end
  end

  describe "timer" do
    describe "start_timer!" do
      it "should set start time to current time if not set" do
        Sudokoup::Clock.stub!(:time).and_return(1291259945)
        @player.start_timer!
        @player.start_time.should == 1291259945
      end
    end

    describe "stop_timer!" do
      before(:each) do
        Sudokoup::Clock.stub!(:time).and_return(1291259945)
        @player.start_timer!
      end
      it "should set stop time to current time" do
        @player.stop_timer!
        @player.stop_time.should == 1291259945
      end

      it "should set last lap time" do
        Sudokoup::Clock.stub!(:time).and_return(1291259945)
        @player.start_timer!
        Sudokoup::Clock.stub!(:time).and_return(1291259955)
        @player.stop_timer!
        @player.last_lap.should == 10
      end
      
      it "should add to total time" do
        Sudokoup::Clock.stub!(:time).and_return(1291259945)
        @player.start_timer!
        Sudokoup::Clock.stub!(:time).and_return(1291259955)
        @player.stop_timer!
        @player.total_time.should == 10

        Sudokoup::Clock.stub!(:time).and_return(1291259965)
        @player.start_timer!
        Sudokoup::Clock.stub!(:time).and_return(1291259985)
        @player.stop_timer!
        @player.total_time.should == 30
      end
    end
  end

end
