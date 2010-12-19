require 'spec_helper'

describe Sudocoup::Server do

  describe "stop" do
    before(:each) do
      @server = Sudocoup::Server.new
      EventMachine.stub!(:stop)
      @server.controller = mock(Sudocoup::Controller, :close => nil)
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
