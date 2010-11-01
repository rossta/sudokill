require 'spec_helper'

describe Sudokl::View::WebSocket do

  describe "self.start" do
    it "should start em websocket server" do
      EM.should_receive(:start_server).with('localhost', 8888, EventMachine::WebSocket::Connection, {})
      Sudokl::View::WebSocket.start(:host => "localhost", :port => 8888)
    end
  end

  describe "self.stop" do
    it "should call em stop" do
      EM.should_receive(:stop)
      Sudokl::View::WebSocket.stop
    end
  end
end
