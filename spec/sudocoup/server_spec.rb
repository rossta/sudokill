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
      @player_2 = mock(Sudocoup::Player::Socket, :number => 2, :current_time => 25, :name => "Player 2", :to_json => %Q|{"number":2}|)
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
  describe "queue_json" do
    before(:each) do
      @player_1 = mock(Sudocoup::Player::Socket, :number => nil, :current_time => 0, :name => "Player 1", :to_json => %Q|{"name":"Player 1"}|, :send =>nil)
      @player_2 = mock(Sudocoup::Player::Socket, :number => nil, :current_time => 0, :name => "Player 2", :to_json => %Q|{"name":"Player 2"}|, :send =>nil)
      @game     = mock(Sudocoup::Game)
      Sudocoup::Game.stub!(:new).and_return(@game)
      @server   = Sudocoup::Server.new(:max_time => 120)
      @server.queue << @player_1
      @server.queue << @player_2
    end
    it "should return TIME message with player ids and times" do
# {
#   players: [
#     {
#       name: 'Player 1'
#     },
#     {
#       name: 'Player 2'
#     }
#   ]
# }
      json_s = @server.queue_json
      json = JSON.parse(json_s)
      json['action'].should == 'QUEUE'
      players = json['players']
      players.size.should == 2
      player_1_json = players.shift
      player_2_json = players.shift
      player_1_json['name'].should == "Player 1"
      player_2_json['name'].should == "Player 2"
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
      @player_1 = mock(Sudocoup::Player::Socket, :number => 1, :send => true, :name => "Player 1")
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
  
  describe "end_game_and_start_new" do
    before(:each) do
      @game     = mock(Sudocoup::Game, :send_players => nil, :available? => false)
      @new_game = mock(Sudocoup::Game, :available? => true, :ready? => false, :join_game => true)
      @channel  = mock(EM::Channel, :push => nil)
      Sudocoup::Game.stub!(:new).and_return(@game)
      EM::Channel.stub!(:new).and_return(@channel)
      @server   = Sudocoup::Server.new
    end
    it "should send game over message to players" do
      @game.should_receive(:send_players).with(/GAME OVER/)
      @server.end_game_and_start_new("Game stopped")
    end
    it "should initialize new game" do
      @server.game.should == @game
      Sudocoup::Game.should_receive(:new).and_return(@new_game)
      @server.end_game_and_start_new("Game stopped")
      @server.game.should == @new_game
    end
    describe "add players to new game" do
      before(:each) do
        Sudocoup::Game.stub!(:new).and_return(@new_game)
        @player_1 = mock(Sudocoup::Player::Socket, :name => "Player 1", :to_json => "Player 1", :send => nil)
        @player_2 = mock(Sudocoup::Player::Socket, :name => "Player 2", :to_json => "Player 2", :send => nil)
        @new_game.stub!(:players).and_return([@player_1, @player_2])
        @server.join_queue @player_1
        @server.join_queue @player_2
      end
      it "should add players from queue" do
        @new_game.should_receive(:join_game).once.with(@player_1).ordered
        @new_game.should_receive(:join_game).once.with(@player_2).ordered
        @server.end_game_and_start_new("Game stopped")
      end
    end
  end
  
  describe "announce_player" do
    before(:each) do
      @player   = mock(Sudocoup::Player::Socket, :name => "Player 1", :to_json => "Player 1", :send => nil)
      @game     = mock(Sudocoup::Game, :players => [])
      @channel  = mock(EM::Channel, :push => nil)
      Sudocoup::Game.stub!(:new).and_return(@game)
      @server = Sudocoup::Server.new
      @server.channel = @channel
    end
    it "should broadcast player json and in game message if player is in game" do
      @game.stub!(:players).and_return([@player])
      @channel.should_receive(:push).once.with(/SCORE/).ordered
      @channel.should_receive(:push).once.with(/Player 1 is now in the game/).ordered
      @server.announce_player @player
    end
    it "should broadcast queue json and on deck message if player is in queue" do
      @server.join_queue(@player)
      @channel.should_receive(:push).once.with(/QUEUE/).ordered
      @channel.should_receive(:push).once.with(/Player 1 is now waiting/).ordered
      @server.announce_player @player
    end
  end
  
  describe "remove_player" do
    before(:each) do
      @player_1 = mock(Sudocoup::Player::Socket, :name => "Player 1", :to_json => "Player 1", :send => nil)
      @player_2 = mock(Sudocoup::Player::Socket, :name => "Player 2", :to_json => "Player 2", :send => nil)
      @player_3 = mock(Sudocoup::Player::Socket, :name => "Player 3", :to_json => "Player 3", :send => nil)
      @game     = mock(Sudocoup::Game, :players => [], :in_progress? => false, :available? => false, :over? => false, :ready? => false)
      @channel  = mock(EM::Channel, :push => nil)
      Sudocoup::Game.stub!(:new).and_return(@game)
      @server = Sudocoup::Server.new
      @server.channel = @channel
    end
    describe "from game in progress" do
      it "should end game and start new" do
        @game.stub!(:players).and_return([@player_1, @player_2])
        @game.should_receive(:in_progress?).and_return(true)
        @game.should_receive(:send_players).with(/GAME OVER/)
        @server.remove_player @player_1
      end
    end
    describe "from game not started" do
      before(:each) do
        @server.join_queue @player_3
        @game.stub!(:players).and_return([@player_1, @player_3])
        @game.stub!(:in_progress?).and_return(false)
        @game.stub!(:over?).and_return(false)
        @game.stub!(:join_game).and_return(true)
      end
      it "should add one player from queue and keep other player" do
        @game.should_receive(:join_game).with(@player_3)
        @server.remove_player @player_1
      end
      it "should broadcast player 3 in game" do
        @channel.should_receive(:push).once.with(/SCORE/).ordered
        @channel.should_receive(:push).once.with(/Player 3 is now in the game/).ordered
        @server.remove_player @player_1
      end
      it "should not end game" do
        @game.should_receive(:in_progress?).and_return(false)
        @game.should_receive(:over?).and_return(false)
        @game.should_not_receive(:send_players).with(/GAME OVER/)
        @server.remove_player @player_1
      end
    end
    describe "from queue" do
      it "should broadcast player left queue" do
        @server.join_queue @player_3
        @channel.should_receive(:push).with(/Player 3 left the On Deck circle/)
        @server.remove_player @player_3
      end
    end
  end
end
