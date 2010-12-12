require 'spec_helper'

describe Sudocoup::Player::Naive do
  before(:each) do
    EventMachine.stub!(:send_data)
    @player = Sudocoup::Player::Naive.new({})
    @add_command = "ADD|7 0 5 0 0 0 2 9 4|0 0 1 2 0 6 0 0 0|0 0 0 0 0 0 0 0 7|9 0 4 5 0 0 0 2 0|0 0 7 3 6 2 1 0 0|0 2 0 0 0 1 7 0 8|1 0 0 0 9 0 0 0 0|0 0 0 7 0 5 9 0 0|5 3 9 0 0 0 8 0 2\r\n"
  end
  describe "receive_data" do
    describe "ADD" do
      it "should respond with an available move" do
        cmd = @add_command
        sample_move = "0 4 8\r\n"
        EventMachine.should_receive(:send_data).with(@player.signature, /\d+ \d+ \d+/, sample_move.size)
        @player.receive_data(cmd)
      end
      it "should choose new row if last move row occupied" do
        cmd = "ADD|7 6 5 1 3 8 2 9 4|0 0 1 2 0 6 0 0 0|0 0 0 0 0 0 0 0 7|9 0 4 5 0 0 0 2 0|0 0 7 3 6 2 1 0 0|0 2 0 0 0 1 7 0 8|1 0 0 0 9 0 0 0 0|0 0 0 7 0 5 9 0 0|5 3 9 0 0 0 8 0 2\r\n"
        @player.last_move = [0, 5, 8, 2]
        @player.receive_data(cmd)
        @player.move.should == "2 5 4"
      end
    end
    describe "move played" do
      it "should store last move" do
        cmd = "0 1 2 1\r\n"
        @player.receive_data(cmd)
        @player.last_move.should == [0, 1, 2, 1]
      end
    end
  end
  
  describe "board methods" do
    before(:each) do
      @player.find_rows(@add_command)
    end
    describe "section" do
      it "should return array of values in 3x3 section" do
        @player.section(3, 3).should == [5, 0, 0, 3, 6, 2, 0, 0, 1]
      end
    end
  
    describe "rows" do
      it "should return values in row" do
        @player.row(3, 3).should == [9, 0, 4, 5, 0, 0, 0, 2, 0]
      end
    end
    
    describe "column" do
      it "should return values in column" do
        @player.column(3, 3).should == [0, 2, 0, 5, 3, 0, 0, 7, 0]
      end
    end
  end
  
  describe "find_rows" do
    it "should return 9x9 array of integer values" do
      cmd = @add_command
      rows = @player.find_rows(cmd)
      rows.size.should  == 9
      rows.first.should == [7, 0, 5, 0, 0, 0, 2, 9, 4]
      rows.last.should  == [5, 3, 9, 0, 0, 0, 8, 0, 2]
    end
  end
end
