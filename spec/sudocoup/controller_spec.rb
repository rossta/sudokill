require 'spec_helper'

describe Sudocoup::Controller do
  before(:each) do
    @pipe = "|"
    @game       = mock(Sudocoup::Game)
    Sudocoup::Game.stub!(:new).and_return(@game)

    @controller = Sudocoup::Controller.new

    @channel  = mock(EM::Channel, :push => nil)
    @controller.channel = @channel
  end
  describe "close" do
    before(:each) do
      @player = mock_player
      @game.stub!(:players).and_return([])
    end
    it "should close players" do
      @game.stub!(:players).and_return([@player])
      @player.should_receive(:close)
      @controller.close
    end
    it "should close players in queue" do
      @controller.queue = [@player]
      @player.should_receive(:close)
      @controller.close
    end
  end

  describe "broadcast" do
    it "should push msg to channel" do
      @channel.should_receive(:push).with("Message")
      @controller.broadcast("Message")
    end
  end

  describe "send_players" do
    it "should send given message to all players in game" do
      player_1 = mock_player
      player_2 = mock_player
      @game.stub!(:players => [player_1, player_2])
      player_1.should_receive(:send_command).with("foobar")
      player_2.should_receive(:send_command).with("foobar")
      @controller.send_players("foobar")
    end
  end

  describe "time_left?" do
    it "should return false if player time left false" do
      player = mock_player(:time_left? => false)
      @controller.time_left?(player).should be_false
    end

    it "should return true if player time left true" do
      player = mock_player(:time_left? => true)
      @controller.time_left?(player).should be_true
    end

    it "should return time left for current player if not given player" do
      @game.stub!(:current_player => mock_player(:time_left? => false))
      @controller.time_left?.should be_false
    end
  end

  describe "commands" do
    
    describe "join_queue" do
      it "should add player to the queue and instruct WAIT" do
        player = mock_player
        player.should_receive(:send_command).with("WAIT")
        @controller.call :join_queue, :player => player
        @controller.queue.size.should == 1
        @controller.queue.first.should == player
      end
    end
    
    describe "join_game" do
      it "should ready player for game" do
        @player_1 = mock_player
        @game.stub!(:join_game => true, :ready? => false, :players => [@player_1])

        @player_1.should_receive(:reset)
        @player_1.should_receive(:send_command).with("READY")
        @controller.call :join_game, :player => @player_1
      end
    end
    
    describe "new_player" do
      before(:each) do
        @player_1 = mock_player
        @game.stub!(:join_game => true, :ready? => false, :players => [@player_1])
      end
      describe "game available" do
        before(:each) do
          @game.stub!(:available?).and_return(true)
        end
        it "should add player to game if available" do
          @game.should_receive(:join_game).with(@player_1)
          @controller.call :new_player, :player => @player_1
        end
        it "should tell player 'READY'" do
          @player_1.should_receive(:send_command).with("READY")
          @controller.call :new_player, :player => @player_1
        end
      end
      describe "game not available" do
        before(:each) do
          @game.stub!(:available?).and_return(false)
        end
        it "should add player to queue" do
          @controller.should_not_receive(:join_queue)
          @controller.call :new_player, :player => @player_1
          @controller.queue.size.should == 1
          @controller.queue.first.should == @player_1
        end
        it "should tell player to 'WAIT'" do
          @player_1.should_receive(:send_command).with("WAIT")
          @controller.call :new_player, :player => @player_1
        end
      end
    end
    
    describe "new_visitor" do
      it "should send appropriate json" do
        @game.stub!(:sudocoup_state => :in_progress, :board => :board, :players => [])
        visitor = mock(Sudocoup::Client::WebSocket, :send => nil, :name => "Websocket Visitor")
        Sudocoup::StatusJSON.should_receive(:to_json).and_return(:status_json)
        Sudocoup::BoardJSON.should_receive(:to_json).and_return(:board_json)
        Sudocoup::PlayerJSON.should_receive(:to_json).and_return(:player_json)
        Sudocoup::QueueJSON.should_receive(:to_json).and_return(:queue_json)
        visitor.should_receive(:send).with(:board_json).once.ordered
        visitor.should_receive(:send).with(:player_json).once.ordered
        visitor.should_receive(:send).with(:queue_json).once.ordered
        @controller.call :new_visitor, :visitor => visitor
      end
    end
    
    describe "remove_player" do
      before(:each) do
        @player_1 = mock_player(:name => "Player 1")
        @player_2 = mock_player(:name => "Player 2")
        @player_3 = mock_player(:name => "Player 3")
        @game.stub!(:players => [@player_1, @player_2], :sudocoup_state => :waiting, :available? => false, :ready? => false)
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
          @controller.call :remove_player, :player => @player_1
        end
        it "should tell remaining player game is over" do
          @player_2.should_receive(:send_command).with(/GAME OVER/)
          @controller.call :remove_player, :player => @player_1
        end
      end
      describe "from game waiting" do
        before(:each) do
          @controller.call :join_queue, :player => @player_3
          @game.stub!(:sudocoup_state).and_return(:waiting)
          @game.stub!(:waiting!).and_return(true)
          @game.stub!(:join_game)
          @game.stub!(:has_player?).and_return(true)
        end
        it "should add one player from queue and keep other player" do
          @game.should_receive(:join_game).with(@player_3)
          @controller.call :remove_player, :player => @player_1
        end
        it "should broadcast player 3 in game" do
          @channel.should_receive(:push).once.with(/Player 3 is now in the game/).ordered
          @channel.should_receive(:push).once.with(/SCORE/).ordered
          @channel.should_receive(:push).once.with(/QUEUE/).ordered
          @controller.call :remove_player, :player => @player_1
        end
        it "should not end game and set it to waiting" do
          @player_1.should_not_receive(:send_command).with(/GAME OVER/)
          @player_2.should_not_receive(:send_command).with(/GAME OVER/)
          @controller.call :remove_player, :player => @player_1
        end
      end
      describe "from game ready" do
        before(:each) do
          @controller.call :join_queue, :player => @player_3
          @game.stub!(:sudocoup_state).and_return(:ready)
          @game.stub!(:ready?).and_return(true)
          @game.stub!(:has_player?).and_return(true)
        end
        it "should set game to waiting add one player from queue and keep other player" do
          @game.should_receive(:waiting!).once.ordered
          @game.should_receive(:join_game).with(@player_3).once.ordered
          @controller.call :remove_player, :player => @player_1
        end
      end
      describe "from queue" do
        it "should broadcast player left queue" do
          @controller.call :join_queue, :player => @player_3
          @channel.should_receive(:push).with(/Player 3 left the On Deck circle/).once.ordered
          @channel.should_receive(:push).with(/QUEUE/).once.ordered
          @controller.call :remove_player, :player => @player_3
        end
      end
    end
    
    describe "announce_player" do
      before(:each) do
        @player   = mock_player(:name => "Player 1")
        @game.stub!(:players => [])
      end
      it "should broadcast player json and in game message if player is in game" do
        @game.stub!(:players).and_return([@player])
        @game.should_receive(:has_player?).and_return(true)
        @channel.should_receive(:push).once.with(/Player 1 is now in the game/).ordered
        @channel.should_receive(:push).once.with(/SCORE/).ordered
        @channel.should_receive(:push).once.with(/QUEUE/).ordered
        @controller.call :announce_player, :player => @player
      end
      it "should broadcast queue json and on deck message if player is in queue" do
        @controller.call :join_queue, :player => @player
        @game.should_receive(:has_player?).and_return(false)
        @channel.should_receive(:push).once.with(/Player 1 is now waiting/).ordered
        @channel.should_receive(:push).once.with(/SCORE/).ordered
        @channel.should_receive(:push).once.with(/QUEUE/).ordered
        @controller.call :announce_player, :player => @player
      end
    end
    
    describe "game_states" do
      before(:each) do
        @player   = mock_player
        @game.stub!(:players => [@player], :available? => false, :sudocoup_state => :in_progress,
          :waiting! => nil, :over! => nil)
        @new_game = mock(Sudocoup::Game, :available? => true, :ready? => false, :join_game => true, :has_player? => true)
      end
      describe "end_game" do
        it "should set game state to over" do
          @game.should_receive(:over!)
          @controller.call :end_game, :msg => "Game stopped"
        end
        it "should send game over message to players" do
          @player.should_receive(:send_command).with(/GAME OVER/)
          @controller.call :end_game, :msg => "Game stopped"
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
          @controller.game.should == @game
          Sudocoup::Game.should_receive(:new).and_return(@new_game)
          @controller.call :new_game
          @controller.game.should == @new_game
        end
        it "should add players from queue" do
          @controller.call :join_queue, :player => @player_1
          @controller.call :join_queue, :player => @player_2
          @new_game.should_receive(:join_game).once.with(@player_1).ordered
          @new_game.should_receive(:join_game).once.with(@player_2).ordered
          @controller.call :new_game
        end
      end
      
      describe "play_game" do
        class FakeDeferrable
          def callback(&block)
            @block = block
          end
          def succeed
            @block.call
          end
        end
        before(:each) do
          Sudocoup::Controller::RequestNextPlayerMoveCommand.stub!(:new).and_return(mock(Sudocoup::Controller::Command, :call => nil))
          EM::DefaultDeferrable.stub!(:new).and_return(FakeDeferrable.new)
          @game.stub!(:ready? => true, :status => nil, :board => mock(Sudocoup::Board), 
            :play! => true, :next_player_request => nil, :current_player => nil, :players => [mock_player])
        end
        it "should build game board with given density" do
          @game.should_receive(:rebuild).with(0.50)
          @controller.call :play_game, :density => 0.50
        end
      end
    end
    
  end
end
