require 'spec_helper'

describe Sudokill::Server do

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
