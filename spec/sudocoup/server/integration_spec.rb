require 'spec_helper'
require 'json'

describe Sudocoup::Server do
  before(:each) do
    @pipe = "|"
  end
  describe "connection on open join game" do
    it "should add players to game if available and respond READY" do
      EM.run {
        server = Sudocoup::Server.new(:host => '0.0.0.0', :port => 12345)
        server.start
        socket = EM.connect('0.0.0.0', 12345, FakeSocketClient)
        socket.onopen = lambda {
          server.players.size.should == 1
          socket.data.last.chomp.should == "READY"
          EM.stop
        }
      }
    end
    it "should add players to queue if game full and respond WAIT" do
      EM.run {
        server = Sudocoup::Server.new(:host => '0.0.0.0', :port => 12345)
        server.start
        socket_1 = EM.connect('0.0.0.0', 12345, FakeSocketClient)
        socket_2 = EM.connect('0.0.0.0', 12345, FakeSocketClient)
        socket_3 = EM.connect('0.0.0.0', 12345, FakeSocketClient)
        socket_3.onopen = lambda {
          server.players.size.should == 2
          server.queue.size.should == 1
          socket_3.data.last.chomp.should == "WAIT"
          EM.stop
        }
      }
    end
  end
  describe "play_game" do
    it "should broadcast game status if not ready" do
      EM.run {
        server = Sudocoup::Server.new(:host => '0.0.0.0', :port => 12345, :ws_port => 56789)
        server.start
        EventMachine.add_timer(0.1) {
          http = EventMachine::HttpRequest.new('ws://127.0.0.1:56789/').get :timeout => 0
          http.callback { server.play_game.succeed }

          http.stream { |msg|
            json = JSON.parse(msg)
            json["message"].should == "Waiting for more players"
            EventMachine.stop
          }
        }
      }
    end
    it "should broadcast game board" do
      EM.run {
        server = Sudocoup::Server.new(:host => '0.0.0.0', :port => 12345, :ws_port => 56789)
        server.start

        # Two players join game
        socket_1 = EM.connect('0.0.0.0', 12345, FakeSocketClient)
        socket_2 = EM.connect('0.0.0.0', 12345, FakeSocketClient)

        processed = false

        # Websocket client
        EventMachine.add_timer(0.1) {
          http = EventMachine::HttpRequest.new('ws://127.0.0.1:56789/').get :timeout => 0
          http.callback { server.play_game.succeed }

          http.stream { |msg|
            json = JSON.parse(msg)
            json['action'].should == "CREATE"
            json['values'].size.should == 9
            json['values'].each do |row|
              row.size.should == 9
              row.each do |val|
                (0..9).should include(val)
              end
            end
            http.stream { |msg| 
              json = JSON.parse(msg)
              json['action'].should == "STATUS"
              json['message'].should == "New game about to begin!"
              http.stream { |msg| 
                json = JSON.parse(msg)
                json['action'].should == "STATUS"
                json['message'].should == "Client's turn!"
              }
            }
            EventMachine.stop
          }
        }
      }
    end
    it "should send start message to both players" do
      EM.run {
        server = Sudocoup::Server.new(:host => '0.0.0.0', :port => 12345, :ws_port => 56789)
        server.start

        # Two players join game
        socket_1 = EM.connect('0.0.0.0', 12345, FakeSocketClient)
        socket_2 = EM.connect('0.0.0.0', 12345, FakeSocketClient)

        socket_2.onopen = lambda {
          server.play_game.succeed
        }
        socket_1.onmessage = lambda { |msg|
          first = msg.split("\r\n").first.split(@pipe)
          first.shift.should == "START"
          first.shift.should == "1"
          first.shift.should == "2"
          9.times do
            first.shift.should =~ /^\d \d \d \d \d \d \d \d \d$/
          end
        }
        socket_2.onmessage = lambda { |msg|
          first = msg.chomp.split(@pipe)
          first.shift.should == "START"
          first.shift.should == "2"
          first.shift.should == "2"
          9.times do
            first.shift.should =~ /^\d \d \d \d \d \d \d \d \d$/
          end
          EM.stop
        }
      }
    end
    it "should send add message to first player" do
      EM.run {
        server = Sudocoup::Server.new(:host => '0.0.0.0', :port => 12345, :ws_port => 56789)
        server.start
        # Two players join game
        socket_1 = EM.connect('0.0.0.0', 12345, FakeSocketClient)
        socket_2 = EM.connect('0.0.0.0', 12345, FakeSocketClient)

        socket_2.onopen = lambda {
          server.play_game.succeed
        }
        socket_1.onmessage = lambda { |msg|
          message = msg.split("\r\n")[1].split(@pipe)
          message.shift.should == "ADD"
          9.times do
            message.shift.should =~ /^\d \d \d \d \d \d \d \d \d$/
          end
          EM.stop
        }
      }
    end
  end
  describe "request_add_move" do
    describe "status: ok" do
      it "should add move to board" do
        EM.run {
          server = Sudocoup::Server.new(:host => '0.0.0.0', :port => 12345, :ws_port => 56789)
          server.start

          # Two players join game
          socket_1 = EM.connect('0.0.0.0', 12345, FakeSocketClient)
          socket_2 = EM.connect('0.0.0.0', 12345, FakeSocketClient)

          socket_2.onopen = lambda {
            server.play_game.succeed
            server.request_add_move.succeed(server.game.players.first, "0 1 6")
          }
          socket_2.onmessage = lambda { |msg|
            # first: START..., second: 0 1 6 (move), third: ADD...
            first, second, third  = msg.split("\r\n")
            second.chomp.should == "0 1 6"
            add_msg = third.chomp.split(@pipe)
            add_msg.shift.should == "ADD"
            9.times do
              add_msg.shift.should =~ /^\d \d \d \d \d \d \d \d \d$/
            end
            EM.stop
          }
        }
      end
      it "should broadcast move" do
        EM.run {
          server = Sudocoup::Server.new(:host => '0.0.0.0', :port => 12345, :ws_port => 56789)
          server.start

          # Two players join game
          socket_1 = EM.connect('0.0.0.0', 12345, FakeSocketClient)
          socket_2 = EM.connect('0.0.0.0', 12345, FakeSocketClient)

          # Websocket client
          EventMachine.add_timer(0.1) {
            http = EventMachine::HttpRequest.new('ws://127.0.0.1:56789/').get :timeout => 0
            http.callback {
              server.play_game.succeed
              server.request_add_move.succeed(server.game.players.first, "0 1 6")
            }

            http.stream { |msg|
              http.stream { |msg|
                begin
                  json = JSON.parse(msg)
                  json['action'].should == "UPDATE"
                  json['value'].should == [0, 1, 6]
                rescue
                  EventMachine.stop
                end
              }
            }
          }
        }
      end
    end
  end
  describe "periodic timer" do
    it "should end game if time is up for player while game in progress" do
      EM.run {
        server = Sudocoup::Server.new(:host => '0.0.0.0', :port => 12345, :ws_port => 56789, :max_time => 120)
        server.start

        # Two players join game
        socket_1 = EM.connect('0.0.0.0', 12345, FakeSocketClient)
        socket_2 = EM.connect('0.0.0.0', 12345, FakeSocketClient)

        socket_2.onopen = lambda {
          server.players.first.total_time = 121
          server.play_game.succeed
          sleep 1.1
        }
        socket_1.onmessage = lambda { |msg|
          first, second, third = msg.split("\r\n")
          third.split(@pipe).first.should == "GAME OVER"
          EM.stop
        }
      }
    end
  end
end