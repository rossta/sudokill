require 'spec_helper'

describe Sudokill::Server do
  
  describe "initialize" do
    before(:each) do
      Sudokill::Controller.stub!(:create!).and_return("controller")
    end
    it "should set defaults" do
      server = Sudokill::Server.new
      server.env.should == :test
      server.host.should == '0.0.0.0'
      server.port.should == 44444
      server.ws_host.should == '0.0.0.0'
      server.ws_port.should == 8080
      server.http_port.should == 4567
    end
    
    it "should accept options" do
      server = Sudokill::Server.new({
        :env => :development,
        :host => 'localhost',
        :port => 454545,
        :ws_host => '127.0.0.1',
        :ws_port => 48080,
        :http_port => 45678
      })
      server.env.should == :development
      server.host.should == 'localhost'
      server.port.should == 454545
      server.ws_host.should == '127.0.0.1'
      server.ws_port.should == 48080
      server.http_port.should == 45678
    end
  end
  
  describe "stop" do
    before(:each) do
      @server = Sudokill::Server.new
      EventMachine.stub!(:stop)
      @server.controller = mock(Sudokill::Controller, :close => nil)
    end
    it "should stop the eventmachine" do
      EventMachine.should_receive(:stop)
      @server.stop
    end
    it "should stop the eventmachine" do
      @server.controller.should_receive(:close)
      @server.stop
    end
  end

end
