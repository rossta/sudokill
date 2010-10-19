module Sudoku

  class Server

    def initialize(opts = {})
      @host   = opts[:host] || 'localhost'
      @port   = (opts[:port] || 8080).to_i
      @debug  = opts[:debug] || false
      @echo   = opts[:echo] || false
    end

    def start!
      return echo! if @echo
      EventMachine.run {
        EventMachine::WebSocket.start(:host => @host, :port => @port, :debug => @debug) do |ws|
          ws.onopen    { ws.send "Welcome to Socket-Sudoku. Game on!"}
          ws.onmessage { |msg| ws.send "Pong: #{msg}" }
          ws.onclose   { puts "WebSocket closed" }
        end
        puts "Sudoku WebSocket server started on #{@host}:#{@port}"
      }
    end

    def stop!
      EventMachine::WebSocket.stop
    end
    
    def echo!
      EventMachine.run {
        EventMachine::WebSocket.start(:host => @host, :port => @port, :debug => @debug) do |ws|
          ws.onopen    { ws.send "Hello Client!"}
          ws.onmessage { |msg| ws.send "Pong: #{msg}" }
          ws.onclose   { puts "WebSocket closed" }
        end
        puts "Echo server started on #{@host}:#{@port}"
      }
    end
    
  end
end

