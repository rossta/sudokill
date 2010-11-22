require 'spec_helper'
require 'json'

describe Sudokoup::Server do
  describe "move_json" do
    it "should return action, move, and status as json object" do
      json_s = subject.move_json("1 2 3", :ok)
      json = JSON.parse(json_s)
      json["action"].should == "UPDATE"
      json["value"].should == [1,2,3]
      json["status"].should == "ok"
    end
  end
  describe "board_json" do
    it "should return action, move, and status as json object" do
      board = mock(Sudokoup::Board, :to_json => "[[1,2,3],[4,5,6],[7,8,9]]", :build => nil)
      Sudokoup::Board.stub!(:new).and_return(board)
      json_s = subject.board_json
      json = JSON.parse(json_s)
      json["action"].should == "CREATE"
      json["values"].should == [[1,2,3],[4,5,6],[7,8,9]]
    end
  end
  describe "start_message" do
    it "should return START | player number | board json" do
      @server = Sudokoup::Server.new
      player_1 = mock(Sudokoup::Player::Socket, :number => 1)
      player_2 = mock(Sudokoup::Player::Socket, :number => 2)
      @server.game.join_game(player_1)
      @server.game.join_game(player_2)
      message = @server.start_message(player_1).split(" | ")
      message.shift.should == "START"
      message.shift.should == "1" # you're player 1
      message.shift.should == "2" # 2 players total
    end
  end
  describe "reject_message" do
    it "should return REJECT | reason ... " do
      reason = "It failed"
      subject.reject_message(reason).should == "REJECT | It failed"
    end
  end
  describe "game_over_message" do
    it "should return GAME OVER | reason... " do
      reason = "You lost"
      subject.game_over_message(reason).should == "GAME OVER | You lost"
    end
  end
  describe "add_message" do
    it "should send MOVE | previous move | board json" do
      @server = Sudokoup::Server.new
      player_1 = mock(Sudokoup::Player::Socket, :number => 1)
      player_2 = mock(Sudokoup::Player::Socket, :number => 2)
      @server.game.join_game(player_1)
      @server.game.join_game(player_2)
      message = @server.add_message("0 1 2").split(" | ")
      message.shift.should == "ADD"
      message.shift.should == "0 1 2"
      9.times do
        message.shift.should =~ /^\d \d \d \d \d \d \d \d \d$/
      end
    end
  end 
end
