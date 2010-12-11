require 'spec_helper'

describe Sudocoup::Player::Naive do
  describe "receive_data" do
    before(:each) do
      EventMachine.stub!(:send_data)
      @player = Sudocoup::Player::Naive.new({})
    end
    describe "ADD" do
      it "should respond with an available move" do
        cmd = "ADD|7 0 5 0 0 0 2 9 4|0 0 1 2 0 6 0 0 0|0 0 0 0 0 0 0 0 7|9 0 4 5 0 0 0 2 0|0 0 7 3 6 2 1 0 0|0 2 0 0 0 1 7 0 8|1 0 0 0 9 0 0 0 0|0 0 0 7 0 5 9 0 0|5 3 9 0 0 0 8 0 2\r\n"
        sample_move = "0 4 8\r\n"
        EventMachine.should_receive(:send_data).with(@player.signature, /\d+ \d+ \d+/, sample_move.size)
        @player.receive_data(cmd)
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
end
