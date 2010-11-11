require 'spec_helper'

describe Sudokoup::WebSocket do

  describe "self.start" do
    it "should start em websocket server" do
      EM.should_receive(:start_server).with('localhost', 8888, EventMachine::WebSocket::Connection, {})
      Sudokoup::WebSocket.start(:host => "localhost", :port => 8888)
    end
  end

  describe "self.stop" do
    it "should call em stop" do
      EM.should_receive(:stop)
      Sudokoup::WebSocket.stop
    end
  end
end
