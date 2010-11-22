require 'spec_helper'

describe Sudokoup::Server do
  describe "socket server" do
    it "should add players to game if available and respond READY" do
      EM.run {
        server = Sudokoup::Server.new(:host => '0.0.0.0', :port => 12345)
        server.start
        connection = EM.connect('0.0.0.0', 12345, FakeSocketClient)
        connection.onopen = lambda {
          server.players.size.should == 1
          connection.data.last.chomp.should == "READY"
          EM.stop
        }
      }
    end
    it "should add players to queue if game full and respond WAIT" do
      EM.run {
        server = Sudokoup::Server.new(:host => '0.0.0.0', :port => 12345)
        server.start
        connection_1 = EM.connect('0.0.0.0', 12345, FakeSocketClient)
        connection_2 = EM.connect('0.0.0.0', 12345, FakeSocketClient)
        connection_3 = EM.connect('0.0.0.0', 12345, FakeSocketClient)
        connection_3.onopen = lambda {
          server.players.size.should == 2
          server.queue.size.should == 1
          connection_3.data.last.chomp.should == "WAIT"
          EM.stop
        }
      }
    end
  end
end