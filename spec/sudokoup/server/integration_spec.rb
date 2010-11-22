require 'spec_helper'
require 'json'

describe Sudokoup::Server do
  describe "connection on open join game" do
    it "should add players to game if available and respond READY" do
      EM.run {
        server = Sudokoup::Server.new(:host => '0.0.0.0', :port => 12345)
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
        server = Sudokoup::Server.new(:host => '0.0.0.0', :port => 12345)
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
        server = Sudokoup::Server.new(:host => '0.0.0.0', :port => 12345, :view => { :port => 56789 })
        server.start
        EventMachine.add_timer(0.1) {
          http = EventMachine::HttpRequest.new('ws://127.0.0.1:56789/').get :timeout => 0
          http.callback { server.play_game.succeed }

          http.stream { |msg|
            msg.should == "Sudokoup: Game waiting for more players"
            EventMachine.stop
          }
        }
      }
    end
    it "should broadcast game board" do
      EM.run {
        server = Sudokoup::Server.new(:host => '0.0.0.0', :port => 12345, :view => { :port => 56789 })
        server.start

        # Two players join game
        socket_1 = EM.connect('0.0.0.0', 12345, FakeSocketClient)
        socket_2 = EM.connect('0.0.0.0', 12345, FakeSocketClient)

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
            EventMachine.stop
          }
        }
      }
    end
    it "should send start message to both players" do
      EM.run {
        server = Sudokoup::Server.new(:host => '0.0.0.0', :port => 12345, :view => { :port => 56789 })
        server.start

        # Two players join game
        socket_1 = EM.connect('0.0.0.0', 12345, FakeSocketClient)
        socket_2 = EM.connect('0.0.0.0', 12345, FakeSocketClient)

        socket_2.onopen = lambda {
          server.play_game.succeed
        }
        socket_1.onmessage = lambda { |msg|
          first = msg.split("\r\n").first.split(" | ")
          first.shift.should == "START"
          first.shift.should == "1"
          first.shift.should == "2"
        }
        socket_2.onmessage = lambda { |msg|
          first = msg.chomp.split(" | ")
          first.shift.should == "START"
          first.shift.should == "2"
          first.shift.should == "2"
          EM.stop
        }
      }
    end
    it "should send add message to first player" do
      EM.run {
        server = Sudokoup::Server.new(:host => '0.0.0.0', :port => 12345, :view => { :port => 56789 })
        server.start
        # Two players join game
        socket_1 = EM.connect('0.0.0.0', 12345, FakeSocketClient)
        socket_2 = EM.connect('0.0.0.0', 12345, FakeSocketClient)

        socket_2.onopen = lambda {
          server.play_game.succeed
        }
        socket_1.onmessage = lambda { |msg|
          message = msg.split("\r\n")[1].split(" | ")
          message.shift.should == "ADD"
          message.shift.should == " - "
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
          server = Sudokoup::Server.new(:host => '0.0.0.0', :port => 12345, :view => { :port => 56789 })
          server.start

          # Two players join game
          socket_1 = EM.connect('0.0.0.0', 12345, FakeSocketClient)
          socket_2 = EM.connect('0.0.0.0', 12345, FakeSocketClient)

          socket_2.onopen = lambda {
            server.play_game.succeed
            server.request_add_move.succeed(server.game.players.first, "0 1 6")
          }
          socket_2.onmessage = lambda { |msg|
            second  = msg.split("\r\n")[1]
            message = second.chomp.split(" | ")
            message.shift.should == "ADD"
            message.shift.should == "0 1 6"
            9.times do
              message.shift.should =~ /^\d \d \d \d \d \d \d \d \d$/
            end
            EM.stop
          }
        }
      end
      it "should broadcast move" do
        EM.run {
          server = Sudokoup::Server.new(:host => '0.0.0.0', :port => 12345, :view => { :port => 56789 })
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
end