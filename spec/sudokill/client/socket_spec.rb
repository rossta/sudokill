require 'spec_helper'
require 'json'

describe Sudokill::Client::Socket do
  before(:each) do
    @dispatch = mock(Sudokill::Dispatch, :name => "Rossta")
    Sudokill::Dispatch.stub!(:new).and_return(@dispatch)
    @player = Sudokill::Client::Socket.new({})
    @app    = mock(Sudokill::Controller)
    @player.app = @app
  end
  
  describe "receive_data" do
    it "should call dispatch if end line encountered" do
      @dispatch.should_receive(:call).with("MESSAGE")
      @player.receive_data("MESSAGE\r\n")
    end
    it "should not call dispatch if end line not encountered" do
      @dispatch.should_not_receive(:call).with("MESSAGE")
      @player.receive_data("MESSAGE")
    end
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
        Sudokill::Clock.stub!(:time).and_return(1291259945)
        @player.start_timer!
        @player.start_time.should == 1291259945
      end
    end

    describe "stop_timer!" do
      before(:each) do
        Sudokill::Clock.stub!(:time).and_return(1291259945)
        @player.start_timer!
      end
      it "should set total time to current time" do
        @player.stop_timer!
        @player.stop_time.should == 1291259945
      end
      it "should set last lap time" do
        Sudokill::Clock.stub!(:time).and_return(1200000045)
        @player.start_timer!
        Sudokill::Clock.stub!(:time).and_return(1200000055)
        @player.stop_timer!
        @player.last_lap.should == 10
      end

      it "should add to total time" do
        Sudokill::Clock.stub!(:time).and_return(1200000045)
        @player.start_timer!
        Sudokill::Clock.stub!(:time).and_return(1200000055)
        @player.stop_timer!
        @player.total_time.should == 10

        Sudokill::Clock.stub!(:time).and_return(1200000065)
        @player.start_timer!
        Sudokill::Clock.stub!(:time).and_return(1200000085)
        @player.stop_timer!
        @player.total_time.should == 30
      end
      it "should set start time and stop time to null" do
        Sudokill::Clock.stub!(:time).and_return(1200000065)
        @player.start_timer!
        Sudokill::Clock.stub!(:time).and_return(1200000085)
        @player.stop_timer!
        @player.start_time.should be_nil
      end
    end

    describe "current_time" do
      it "should return time now - start time + total time if timer started" do
        @player.has_turn!
        @player.total_time = 25
        Sudokill::Clock.stub!(:time).and_return(1200000045)
        @player.start_timer!
        Sudokill::Clock.stub!(:time).and_return(1200000055)
        @player.current_time.should == 35
      end
      it "should return total time if doesn't have turn" do
        @player.total_time = 25
        @player.current_time.should == 25
      end
    end

  end

  describe "to_json" do
    before(:each) do
      @player.number = 1
      @player.total_time = 14
      @player.name = "Rossta"
      @player.has_turn!
    end
    it "should return TIME message with player ids and times" do
#     {
#       number: 1,
#       current_time: 14,
#       name: 'Player 1',
#       moves: 3
#     }
      json_s = @player.to_json

      json = JSON.parse(json_s)
      json['number'].should == 1
      json['name'].should == 'Rossta'
      json['moves'].should == 0
      json['current_time'].should == 14
      json['has_turn'].should be_true
    end
    it "should not include values that are not defined" do
#     {
#       current_time: 0,
#       name: 'Player 1',
#       moves: []
#     }
      @player.number = nil
      @player.total_time = nil
      @player.waiting!

      json_s = @player.to_json

      json = JSON.parse(json_s)
      json['number'].should be_nil
      json['name'].should == 'Rossta'
      json['moves'].should == 0
      json['current_time'].should == 0
      json['has_turn'].should be_false
    end
  end

  describe "add_move" do
    it "should add move to move list" do
      move = mock(Sudokill::Move)
      Sudokill::Move.should_receive(:new).with(0, 1, 2).and_return(move)
      @player.add_move(0, 1, 2)
      @player.moves.should == [move]
    end
  end

  describe "unbind" do
    it "should remove player from app" do
      @app.should_receive(:call).with(:remove_player, :player => @player)
      @player.unbind
    end
  end
  
  describe "time_left?" do
    before(:each) do
      @max_time = 120
    end
    it "should return true if player time is less than max time" do
      @player.total_time = 60
      @player.time_left?(@max_time).should be_true
    end

    it "should return true if player time is equal to max time" do
      @player.total_time = 120
      @player.time_left?(@max_time).should be_true
    end

    it "should return false if player time is more than max time" do
      @player.total_time = 121
      @player.time_left?(@max_time).should be_false
    end
    it "should return true if no max time" do
      @player.total_time = 121
      @player.time_left?.should be_true
    end
  end

end