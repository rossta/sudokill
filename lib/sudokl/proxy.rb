module Sudokl

  class Proxy < EventMachine::Connection
    attr_accessor :websocket

    def receive_data(data)
      (@buf ||= '') << data
      if line = @buf.slice!(/(.+)\r?\n/)
        log "Server >> #{line}"
        send_data("Proxy >> #{line}")
        @websocket.send(line) if @websocket
      end
    end

  end

end