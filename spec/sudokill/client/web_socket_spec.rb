require 'spec_helper'

describe Sudokill::Client::WebSocket do
  before(:each) do
    @conn   = mock(EventMachine::Connection, :send_data => nil)
    @app    = mock(Sudokill::Controller, :call => nil)
    @player = Sudokill::Client::WebSocket.new({})
    @player.name = "Rossta"
    @player.app   = @app
    @player.conn  = @conn
    def @player.send_data(data)
      @conn.send_data(data)
    end
  end

  describe "message_received" do
    it "should strip html tags" do
      @app.should_receive(:broadcast).with("alert('foo')", "Rossta")
      @player.message_received("<script>alert('foo')</script>\r\n");
    end
    describe "MOVE" do
      it "should request add move callback if playing" do
        @player.has_turn!
        @app.should_receive(:call).with(:request_add_move, :player => @player, :move => "1 2 3")
        @player.message_received("MOVE|1 2 3\r\n")
      end
      it "should not request add move callback if not playing" do
        @app.should_not_receive(:call).with(:request_add_move)
        @player.message_received("MOVE|1 2 3\r\n")
      end
    end
    describe "STOP" do
      it "should trigger stop game callback" do
        @app.should_receive(:call).with(:stop_game)
        @player.message_received("STOP\r\n")
      end
    end
    describe "PLAY" do
      it "should trigger play game callback" do
        @app.should_receive(:call).with(:play_game, :density => 0.33 )
        @player.message_received("PLAY|33\r\n")
      end
    end
    describe "JOIN" do
      it "should trigger new player callback" do
        @app.should_receive(:call).with(:new_player, :player => @player).once.ordered
        @app.should_receive(:call).with(:announce_player, :player => @player).once.ordered
        @player.message_received("JOIN\r\n")
      end
    end
    describe "LEAVE" do
      it "should trigger new player callback" do
        @app.should_receive(:call).with(:remove_player, :player => @player)
        @player.message_received("LEAVE\r\n")
      end
    end
    describe "NEW CONNECTION" do
      it "should send app board json" do
        @app.should_receive(:call).with(:new_visitor, :visitor => @player)
        @player.message_received("NEW CONNECTION|Rossta\r\n")
      end
    end
    describe "SWITCH" do
      it "should request new app" do
        @app.should_receive(:call).with(:switch_controller, :visitor => @player)
        @player.message_received("SWITCH\r\n")
      end
    end
    describe "PREVIEW" do
      it "should request a preview of the current board game" do
        @app.should_receive(:call).with(:preview_board, :density => 0.45)
        @player.message_received("PREVIEW|45\r\n")
      end
    end
  end

  describe "unbind" do
    it "should remove player from app" do
      @player.stub!(:error? => false)
      @app.should_receive(:call).with(:remove_player, :player => @player).once.ordered
      @app.should_receive(:call).with(:remove_visitor, :visitor => @player).once.ordered
      @player.unbind
    end
  end

  describe "send_command" do
    it "should wrap command in command json message" do
      @player.should_receive(:send).with(/\"action\":\"COMMAND\"/)
      @player.send_command("ADD")
      @player.should_receive(:send).with(/\"command\":\"ADD\"/)
      @player.send_command("ADD")
    end
  end

  describe "reset" do
    it "should set reset timers" do
      Sudokill::Clock.stub!(:time).and_return(1200000045)
      @player.start_timer!
      Sudokill::Clock.stub!(:time).and_return(1200000055)
      @player.stop_timer!

      @player.reset
      @player.start_time.should be_nil
      @player.stop_time.should be_nil
      @player.last_lap.should be_nil
      @player.total_time.should == 0
    end
    it "should empty moves" do
      @player.add_move 1, 2, 3
      @player.reset
      @player.moves.should be_empty
    end
  end

end
