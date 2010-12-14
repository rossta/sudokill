require 'spec_helper'
require 'json'

describe Sudocoup::Server do
  before(:each) do
    @pipe = "|"
  end
  describe "start_message" do
    it "should return START | player number | board json" do
      @server = Sudocoup::Server.new
      player_1 = mock_player(:number => 1)
      player_2 = mock_player(:number => 2)
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
      player_1 = mock_player(:number => 1)
      player_2 = mock_player(:number => 2)
      @server.game.join_game(player_1)
      @server.game.join_game(player_2)
      message = @server.add_message.split(@pipe)
      message.shift.should == "ADD"
      9.times do
        message.shift.should =~ /^\d \d \d \d \d \d \d \d \d$/
      end
    end
  end
  describe "join_game" do
    it "should ready player for game" do
      @player_1 = mock_player
      @game = mock(Sudocoup::Game, :join_game => true, :ready? => false, :players => [@player_1])
      Sudocoup::Game.stub!(:new).and_return(@game)
      @server = Sudocoup::Server.new

      @player_1.should_receive(:reset)
      @player_1.should_receive(:send_command).with("READY")
      @server.join_game(@player_1)
    end
  end
  describe "new_player" do
    before(:each) do
      @player_1 = mock_player
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
        @player_1.should_receive(:send_command).with("READY")
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
        @player_1.should_receive(:send_command).with("WAIT")
        @server.new_player(@player_1)
      end
    end
  end

  describe "new_visitor" do
    it "should send appropriate json" do
      visitor = mock(Sudocoup::Client::WebSocket, :send => nil)
      visitor.should_receive(:send).with(subject.board_json).once.ordered
      visitor.should_receive(:send).with(subject.player_json).once.ordered
      visitor.should_receive(:send).with(subject.queue_json).once.ordered
      subject.new_visitor visitor
    end
  end

  describe "time_left?" do
    before(:each) do
      subject.max_time = 120
    end
    it "should return true if player time is less than max time" do
      player = mock_player(:current_time => 60)
      subject.time_left?(player).should be_true
    end

    it "should return true if player time is equal to max time" do
      player = mock_player(:current_time => 120)
      subject.time_left?(player).should be_true
    end

    it "should return false if player time is more than max time" do
      player = mock_player(:current_time => 121)
      subject.time_left?(player).should be_false
    end
  end

  describe "game_states" do
    before(:each) do
      @player   = mock_player
      @game     = mock(Sudocoup::Game, :players => [@player],
        :available? => false, :sudocoup_state => :in_progress, :waiting! => nil, :over! => nil)
      @new_game = mock(Sudocoup::Game, :available? => true, :ready? => false, :join_game => true, :has_player? => true)
      @channel  = mock(EM::Channel, :push => nil)
      Sudocoup::Game.stub!(:new).and_return(@game)
      EM::Channel.stub!(:new).and_return(@channel)
      @server   = Sudocoup::Server.new
    end
    describe "end_game" do
      it "should set game state to over" do
        @game.should_receive(:over!)
        @server.end_game("Game stopped")
      end
      it "should send game over message to players" do
        @player.should_receive(:send_command).with(/GAME OVER/)
        @server.end_game("Game stopped")
      end
    end
    describe "new_game" do
      before(:each) do
        Sudocoup::Game.stub!(:new).and_return(@new_game)
        @player_1 = mock_player(:name => "Player 1")
        @player_2 = mock_player(:name => "Player 2")
        @new_game.stub!(:players).and_return([@player_1, @player_2])
      end
      it "should initialize new game" do
        @server.game.should == @game
        Sudocoup::Game.should_receive(:new).and_return(@new_game)
        @server.new_game
        @server.game.should == @new_game
      end
      it "should add players from queue" do
        @server.join_queue @player_1
        @server.join_queue @player_2
        @new_game.should_receive(:join_game).once.with(@player_1).ordered
        @new_game.should_receive(:join_game).once.with(@player_2).ordered
        @server.new_game
      end
    end
  end


  describe "announce_player" do
    before(:each) do
      @player   = mock_player(:name => "Player 1")
      @game     = mock(Sudocoup::Game, :players => [])
      @channel  = mock(EM::Channel, :push => nil)
      Sudocoup::Game.stub!(:new).and_return(@game)
      @server = Sudocoup::Server.new
      @server.channel = @channel
    end
    it "should broadcast player json and in game message if player is in game" do
      @game.stub!(:players).and_return([@player])
      @game.should_receive(:has_player?).and_return(true)
      @channel.should_receive(:push).once.with(/Player 1 is now in the game/).ordered
      @channel.should_receive(:push).once.with(/SCORE/).ordered
      @channel.should_receive(:push).once.with(/QUEUE/).ordered
      @server.announce_player @player
    end
    it "should broadcast queue json and on deck message if player is in queue" do
      @server.join_queue(@player)
      @game.should_receive(:has_player?).and_return(false)
      @channel.should_receive(:push).once.with(/Player 1 is now waiting/).ordered
      @channel.should_receive(:push).once.with(/SCORE/).ordered
      @channel.should_receive(:push).once.with(/QUEUE/).ordered
      @server.announce_player @player
    end
  end

  describe "remove_player" do
    before(:each) do
      @player_1 = mock_player(:name => "Player 1")
      @player_2 = mock_player(:name => "Player 2")
      @player_3 = mock_player(:name => "Player 3")
      @game     = mock(Sudocoup::Game, :players => [@player_1, @player_2], 
        :sudocoup_state => :waiting, :available? => false, :ready? => false)
      @channel  = mock(EM::Channel, :push => nil)
      Sudocoup::Game.stub!(:new).and_return(@game)
      @server = Sudocoup::Server.new
      @server.channel = @channel
    end
    describe "from game in progress" do
      before(:each) do
        @game.stub!(:sudocoup_state).and_return(:in_progress)
        @game.stub!(:over!)
        @new_game = mock(Sudocoup::Game, :available? => true)
        Sudocoup::Game.should_receive(:new).and_return(@new_game)
      end
      it "should end game and start new" do
        @game.should_receive(:over!).once.ordered
        @new_game.should_receive(:available?).once.ordered
        @server.remove_player @player_1
      end
      it "should tell remaining player game is over" do
        @player_2.should_receive(:send_command).with(/GAME OVER/)
        @server.remove_player @player_1
      end
    end
    describe "from game waiting" do
      before(:each) do
        @server.join_queue @player_3
        @game.stub!(:sudocoup_state).and_return(:waiting)
        @game.stub!(:waiting!).and_return(true)
        @game.stub!(:join_game)
        @game.stub!(:has_player?).and_return(true)
      end
      it "should add one player from queue and keep other player" do
        @game.should_receive(:join_game).with(@player_3)
        @server.remove_player @player_1
      end
      it "should broadcast player 3 in game" do
        @channel.should_receive(:push).once.with(/Player 3 is now in the game/).ordered
        @channel.should_receive(:push).once.with(/SCORE/).ordered
        @channel.should_receive(:push).once.with(/QUEUE/).ordered
        @server.remove_player @player_1
      end
      it "should not end game and set it to waiting" do
        @player_1.should_not_receive(:send_command).with(/GAME OVER/)
        @player_2.should_not_receive(:send_command).with(/GAME OVER/)
        @server.remove_player @player_1
      end
    end
    describe "from game ready" do
      before(:each) do
        @server.join_queue @player_3
        @game.stub!(:sudocoup_state).and_return(:ready)
        @game.stub!(:ready?).and_return(true)
        @game.stub!(:has_player?).and_return(true)
      end
      it "should set game to waiting add one player from queue and keep other player" do
        @game.should_receive(:waiting!).once.ordered
        @game.should_receive(:join_game).with(@player_3).once.ordered
        @server.remove_player @player_1
      end
    end
    describe "from queue" do
      it "should broadcast player left queue" do
        @server.join_queue @player_3
        @channel.should_receive(:push).with(/Player 3 left the On Deck circle/).once.ordered
        @channel.should_receive(:push).with(/QUEUE/).once.ordered
        @server.remove_player @player_3
      end
    end
  end

  describe "send_players" do
    it "should send given message to all players in game" do
      player_1 = mock_player
      player_2 = mock_player
      game     = mock(Sudocoup::Game, :players => [player_1, player_2])
      Sudocoup::Game.stub!(:new).and_return(game)
      @server = Sudocoup::Server.new
      player_1.should_receive(:send_command).with("foobar")
      player_2.should_receive(:send_command).with("foobar")
      @server.send_players("foobar")
    end
  end

end
