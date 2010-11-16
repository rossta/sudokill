require 'spec_helper'
require 'json'

describe Sudokoup::Connection::WebSocket do
  # before(:each) do
  #   @request = {
  #     :port => 80,
  #     :method => "GET",
  #     :path => "/demo",
  #     :headers => {
  #       'Host' => 'example.com',
  #       'Connection' => 'Upgrade',
  #       'Sec-WebSocket-Key2' => '12998 5 Y3 1  .P00',
  #       'Sec-WebSocket-Protocol' => 'sample',
  #       'Upgrade' => 'WebSocket',
  #       'Sec-WebSocket-Key1' => '4 @1  46546xW%0l 1 5',
  #       'Origin' => 'http://example.com'
  #     },
  #     :body => '^n:ds[4U'
  #   }
  # 
  #   @response = {
  #     :headers => {
  #       "Upgrade" => "WebSocket",
  #       "Connection" => "Upgrade",
  #       "Sec-WebSocket-Location" => "ws://example.com/demo",
  #       "Sec-WebSocket-Origin" => "http://example.com",
  #       "Sec-WebSocket-Protocol" => "sample"
  #     },
  #     :body => "8jKS\'y:G*Co,Wxa-"
  #   }
  # end
  # 
  # describe "receive_data" do
  # 
  #   describe "NEW CONNECTION" do
  #     it "should send data: board json" do
  #       board = stub(Sudokoup::Board, :to_json => '[[1, 2, 3],[4, 5, 6],[7, 8, 9]]')
  #       data = %Q|{"action":"CREATE","values":#{board.to_json}}|
  # 
  #       EM.run do
  #         EM.add_timer(0.1) do
  # 
  #           EventMachine::start_server '0.0.0.0', 12345, Sudokoup::Connection::WebSocket, {} do |ws|
  #             ws.app = stub(Sudokoup::Server, :board => board)
  #           end
  # 
  #           # Create a fake client which sends draft 76 handshake
  #           connection = EM.connect('0.0.0.0', 12345, FakeWebSocketClient)
  #           connection.send_data(format_request(@request))
  # 
  #           connection.onmessage = lambda {
  #             connection.response.should == data + "\n"
  #             json = JSON.parse(connection.response)
  #             json["action"].should == "CREATE"
  #             json["values"].should == [[1, 2, 3],[4, 5, 6],[7, 8, 9]]
  #             EM.stop
  #           }
  #           connection.send_data("NEW CONNECTION\r\n")
  #         end
  #       end
  # 
  #     end
  #   end
  # 
  #   describe "UPDATE" do
  #     it "should send data: current json" do
  #       move = stub(Sudokoup::Move, :to_json => '[1, 2, 3]')
  #       data = %Q|{"action":"UPDATE","value":#{move.to_json}}|
  # 
  #       EM.run do
  #         EM.add_timer(0.1) do
  # 
  #           EventMachine::start_server '0.0.0.0', 12345, Sudokoup::Connection::WebSocket, {} do |ws|
  #             ws.app = stub(Sudokoup::Server, :current_move => move)
  #           end
  # 
  #           connection = EM.connect('0.0.0.0', 12345, FakeWebSocketClient)
  #           connection.send_data(format_request(@request))
  # 
  #           connection.onmessage = lambda {
  #             connection.response.should == data + "\n"
  #             json = JSON.parse(connection.response)
  #             json["action"].should == "UPDATE"
  #             json["value"].should == [1, 2, 3]
  #             EM.stop
  #           }
  #           connection.send_data("UPDATE\r\n")
  #         end
  #       end
  # 
  #     end
  #   end
  # end
end
