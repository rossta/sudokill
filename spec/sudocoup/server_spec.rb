require 'spec_helper'
require 'json'

describe Sudocoup::Server do
  before(:each) do
    @pipe = "|"
  end
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
      board = mock(Sudocoup::Board, :to_json => "[[1,2,3],[4,5,6],[7,8,9]]", :build => nil)
      Sudocoup::Board.stub!(:new).and_return(board)
      json_s = subject.board_json
      json = JSON.parse(json_s)
      json["action"].should == "CREATE"
      json["values"].should == [[1,2,3],[4,5,6],[7,8,9]]
    end
  end
  describe "status_json" do
    it "should return action and given message as json" do
      json_s = subject.status_json("Game is starting!");
      json = JSON.parse(json_s)
      json["action"].should == "STATUS"
      json["message"].should == "Game is starting!"
    end
  end
  describe "player_json" do
    before(:each) do
      @player_1 = mock(Sudocoup::Player::Socket, :number => 1, :current_time => 14, :name => "Player 1", :to_json => %Q|{"number":1}|)
      @player_2 = mock(Sudocoup::Player::Socket, :number => 2, :current_time => 25, :name => "Player 1", :to_json => %Q|{"number":2}|)
      @game     = mock(Sudocoup::Game, :players => [@player_1, @player_2])
      Sudocoup::Game.stub!(:new).and_return(@game)
      @server   = Sudocoup::Server.new(:max_time => 120)
    end
    it "should return TIME message with player ids and times" do
# {
#   players: [
#     {
#       number: 1,
#       time: {
#         current: 14,
#         max: 120
#       },
#       name: 'Player 1',
#       moves: 3
#     },
#     {
#       number: 2,
#       time: {
#         current: 25,
#         max: 120
#       },
#       name: 'Player 2',
#       moves: 2
#     }
#   ]
# }
      json_s = @server.player_json
      json = JSON.parse(json_s)
      json['action'].should == 'SCORE'
      players = json['players']
      players.size.should == 2
      player_1_json = players.shift
      player_1_json['number'].should == 1
    end
  end
  describe "start_message" do
    it "should return START | player number | board json" do
      @server = Sudocoup::Server.new
      player_1 = mock(Sudocoup::Player::Socket, :number => 1)
      player_2 = mock(Sudocoup::Player::Socket, :number => 2)
      @server.game.join_game(player_1)
      @server.game.join_game(player_2)
      message = @server.start_message(player_1).split(@pipe)
      message.shift.should == "START"
      message.shift.should == "1" # you're player 1
      message.shift.should == "2" # 2 players total
      9.times do
        message.shift.should =~ /^\d \d \d \d \d \d \d \d \d$/
      end
    end
  end
  describe "reject_message" do
    it "should return REJECT | reason ... " do
      reason = "It failed"
      subject.reject_message(reason).should == "REJECT#{@pipe}It failed"
    end
  end
  describe "game_over_message" do
    it "should return GAME OVER | reason... " do
      reason = "You lost"
      subject.game_over_message(reason).should == "GAME OVER#{@pipe}You lost"
    end
  end
  describe "add_message" do
    it "should send MOVE | previous move | board json" do
      @server = Sudocoup::Server.new
      player_1 = mock(Sudocoup::Player::Socket, :number => 1)
      player_2 = mock(Sudocoup::Player::Socket, :number => 2)
      @server.game.join_game(player_1)
      @server.game.join_game(player_2)
      message = @server.add_message.split(@pipe)
      message.shift.should == "ADD"
      9.times do
        message.shift.should =~ /^\d \d \d \d \d \d \d \d \d$/
      end
    end
  end
  describe "new_player" do
    before(:each) do
      @player_1 = mock(Sudocoup::Player::Socket, :number => 1, :send => true)
      @game = mock(Sudocoup::Game, :join_game => true, :ready? => false, :players => [@player_1])
      Sudocoup::Game.stub!(:new).and_return(@game)
      @server = Sudocoup::Server.new
    end
    describe "game available" do
      before(:each) do
        @game.stub!(:available?).and_return(true)
      end
      it "should add player to game if available" do
        @game.should_receive(:join_game).with(@player_1)
        @server.new_player @player_1
      end
      it "should tell player 'READY'" do
        @player_1.should_receive(:send).with("READY")
        @server.new_player @player_1
      end
    end
    describe "game not available" do
      before(:each) do
        @game.stub!(:available?).and_return(false)
      end
      it "should add player to queue" do
        @game.should_not_receive(:join_queue)
        @server.new_player @player_1
        @server.queue.size.should == 1
        @server.queue.first.should == @player_1
      end
      it "should tell player to 'WAIT'" do
        @player_1.should_receive(:send).with("WAIT")
        @server.new_player(@player_1)
      end
    end
  end

  describe "time_left?" do
    before(:each) do
      subject.max_time = 120
    end
    it "should return true if player time is less than max time" do
      player = mock(Sudocoup::Player::Socket, :current_time => 60)
      subject.time_left?(player).should be_true
    end

    it "should return true if player time is equal to max time" do
      player = mock(Sudocoup::Player::Socket, :current_time => 120)
      subject.time_left?(player).should be_true
    end

    it "should return false if player time is more than max time" do
      player = mock(Sudocoup::Player::Socket, :current_time => 121)
      subject.time_left?(player).should be_false
    end
  end
end
