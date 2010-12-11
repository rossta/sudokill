require 'spec_helper'

describe Sudocoup::Player::WebSocket do
  before(:each) do
    @conn   = mock(EventMachine::Connection, :send_data => nil)
    @app    = mock(Sudocoup::Server,
      :remove_player => nil,
      :play_game => mock(EM::Deferrable, :succeed => true),
      :stop_game => mock(EM::Deferrable, :succeed => true),
      :request_add_move => mock(EM::Deferrable, :succeed => true)
    )
    @player = Sudocoup::Player::WebSocket.new({})
    @player.app   = @app
    @player.conn  = @conn
    def @player.send_data(data)
      @conn.send_data(data)
    end
  end

  describe "receive_data" do
    describe "\d+ \d+ \d+" do
      it "should request add move callback" do
        callback  = mock(Proc)
        deferr    = mock(EM::Deferrable, :succeed => callback)
        @app.should_receive(:request_add_move).and_return(callback)
        callback.should_receive(:succeed).with(@player, "1 2 3")
        @player.receive_data("1 2 3\r\n")
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
    describe "NEW CONNECTION" do
      it "should send app board json" do
        @app.should_receive(:board_json).and_return("board_json")
        @conn.should_receive(:send_data).with(/board_json/)
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
end
