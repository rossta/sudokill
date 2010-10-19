module Sudokl

  class Proxy < EventMachine::Connection
    attr_accessor :websocket

    def receive_data(data)
      puts "Server >> #{data}"
      send_data("Proxy >> #{data}")
      @websocket.send(data) if @websocket
    end

  end

end