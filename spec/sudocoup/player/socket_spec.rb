require 'spec_helper'

describe Sudocoup::Player::Socket do
  before(:each) do
    @player = Sudocoup::Player::Socket.new({})
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
        Sudocoup::Clock.stub!(:time).and_return(1291259945)
        @player.start_timer!
        @player.start_time.should == 1291259945
      end
    end

    describe "stop_timer!" do
      before(:each) do
        Sudocoup::Clock.stub!(:time).and_return(1291259945)
        @player.start_timer!
      end
      it "should set total time to current time" do
        @player.stop_timer!
        @player.stop_time.should == 1291259945
      end
      it "should set last lap time" do
        Sudocoup::Clock.stub!(:time).and_return(1200000045)
        @player.start_timer!
        Sudocoup::Clock.stub!(:time).and_return(1200000055)
        @player.stop_timer!
        @player.last_lap.should == 10
      end

      it "should add to total time" do
        Sudocoup::Clock.stub!(:time).and_return(1200000045)
        @player.start_timer!
        Sudocoup::Clock.stub!(:time).and_return(1200000055)
        @player.stop_timer!
        @player.total_time.should == 10

        Sudocoup::Clock.stub!(:time).and_return(1200000065)
        @player.start_timer!
        Sudocoup::Clock.stub!(:time).and_return(1200000085)
        @player.stop_timer!
        @player.total_time.should == 30
      end
      it "should set start time and stop time to null" do
        Sudocoup::Clock.stub!(:time).and_return(1200000065)
        @player.start_timer!
        Sudocoup::Clock.stub!(:time).and_return(1200000085)
        @player.stop_timer!
        @player.start_time.should be_nil
      end
    end

    describe "current_time" do
      it "should return time now - start time + total time if timer started" do
        @player.has_turn!
        @player.total_time = 25
        Sudocoup::Clock.stub!(:time).and_return(1200000045)
        @player.start_timer!
        Sudocoup::Clock.stub!(:time).and_return(1200000055)
        @player.current_time.should == 35
      end
      it "should return total time if doesn't have turn" do
        @player.total_time = 25
        @player.current_time.should == 25
      end
    end
  end

end
