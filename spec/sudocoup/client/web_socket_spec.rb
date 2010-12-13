require 'spec_helper'

describe Sudocoup::Client::WebSocket do
  before(:each) do
    @conn   = mock(EventMachine::Connection, :send_data => nil)
    @app    = mock(Sudocoup::Server,
      :remove_player => nil,
      :play_game => mock(EM::Deferrable, :succeed => true),
      :stop_game => mock(EM::Deferrable, :succeed => true),
      :request_add_move => mock(EM::Deferrable, :succeed => true)
    )
    @player = Sudocoup::Client::WebSocket.new({})
    @player.app   = @app
    @player.conn  = @conn
    def @player.send_data(data)
      @conn.send_data(data)
    end
  end

  describe "receive_data" do
    describe "MOVE" do
      it "should request add move callback if playing" do
        callback  = mock(Proc)
        @player.has_turn!
        @app.should_receive(:request_add_move).and_return(callback)
        callback.should_receive(:succeed).with(@player, "1 2 3")
        @player.receive_data("MOVE|1 2 3\r\n")
      end
      it "should not request add move callback if not playing" do
        @app.should_not_receive(:request_add_move)
        @player.receive_data("MOVE|1 2 3\r\n")
      end
    end
    describe "STOP" do
      it "should trigger stop game callback" do
        @app.should_receive(:stop_game)
        @player.receive_data("STOP\r\n")
      end
    end
    describe "PLAY" do
      it "should trigger play game callback" do
        @app.should_receive(:play_game)
        @player.receive_data("PLAY\r\n")
      end
    end
    describe "JOIN" do
      it "should trigger new player callback" do
        @app.should_receive(:new_player).with(@player).once.ordered
        @app.should_receive(:announce_player).with(@player).once.ordered
        @player.receive_data("JOIN\r\n")
      end
    end
    describe "LEAVE" do
      it "should trigger new player callback" do
        @app.should_receive(:remove_player).with(@player)
        @player.receive_data("LEAVE\r\n")
      end
    end
    describe "NEW CONNECTION" do
      it "should send app board json" do
        @app.should_receive(:new_visitor)
        @player.receive_data("NEW CONNECTION|Rossta\r\n")
      end
    end
  end

  describe "unbind" do
    it "should remove player from app" do
      @app.should_receive(:remove_player).with(@player)
      @player.unbind
    end
  end

  describe "send_command" do
    it "should wrap command in command json message" do
      @conn.should_receive(:send_data).with(/\"action\":\"COMMAND\"/)
      @player.send_command("ADD")
      @conn.should_receive(:send_data).with(/\"command\":\"ADD\"/)
      @player.send_command("ADD")
    end
  end
  
  describe "reset" do
    it "should set reset timers" do
      Sudocoup::Clock.stub!(:time).and_return(1200000045)
      @player.start_timer!
      Sudocoup::Clock.stub!(:time).and_return(1200000055)
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
