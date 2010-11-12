require 'spec_helper'
require 'json'

describe Sudokoup::ViewHandler do
  describe "receive_data" do

    describe "NEW CONNECTION" do
      it "should send data: board json" do
        board = stub(Sudokoup::Board, :to_json => '[[1, 2, 3],[4, 5, 6],[7, 8, 9]]')
        data = %Q|{"action":"CREATE","values":#{board.to_json}}|

        EM.run do
          EM.add_timer(0.1) do

            EventMachine::start_server '0.0.0.0', 12345, Sudokoup::ViewHandler do |handler|
              handler.app = stub(Sudokoup::Server, :board => board)
            end

            connection = EM.connect('0.0.0.0', 12345, FakeWebSocketProxy)

            connection.onmessage = lambda {
              connection.response.should == data + "\n"
              json = JSON.parse(connection.response)
              json["action"].should == "CREATE"
              json["values"].should == [[1, 2, 3],[4, 5, 6],[7, 8, 9]]
              EM.stop
            }
            connection.send_data("NEW CONNECTION\r\n")
          end
        end

      end
    end

    describe "UPDATE" do
      it "should send data: current json" do
        move = stub(Sudokoup::Move, :to_json => '[1, 2, 3]')
        data = %Q|{"action":"UPDATE","value":#{move.to_json}}|

        EM.run do
          EM.add_timer(0.1) do

            EventMachine::start_server '0.0.0.0', 12345, Sudokoup::ViewHandler do |handler|
              handler.app = stub(Sudokoup::Server, :current_move => move)
            end

            connection = EM.connect('0.0.0.0', 12345, FakeWebSocketProxy)

            connection.onmessage = lambda {
              connection.response.should == data + "\n"
              json = JSON.parse(connection.response)
              json["action"].should == "UPDATE"
              json["value"].should == [1, 2, 3]
              EM.stop
            }
            connection.send_data("UPDATE\r\n")
          end
        end

      end
    end
  end
end