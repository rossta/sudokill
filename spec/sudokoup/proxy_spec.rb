require 'spec_helper'

describe Sudokoup::Proxy do

  describe "receive_data" do
    before(:each) do
      @proxy = Sudokoup::Proxy.new(mock(EventMachine))
      @proxy.stub!(:send_data)
    end
    it "should acknowledge data received to server" do
      @proxy.should_receive(:send_data).with(/data\n/)
      @proxy.receive_data("data\n")
    end

    it "should forward data to websocket if present" do
      @proxy.websocket = mock(EventMachine::WebSocket)
      @proxy.websocket.should_receive(:send).with("data\n")
      @proxy.receive_data("data\n")
    end
  end

end
