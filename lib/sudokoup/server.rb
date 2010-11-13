module Sudokoup
  class Server

    def self.start(opts = {})
      new(opts).start
    end

    attr_reader :board

    def initialize(opts = {})
      @host = opts[:host] || '0.0.0.0'
      @port = opts[:port] || 44444
      @ws_host = opts[:view] && opts[:view][:host] || '0.0.0.0'
      @ws_port = opts[:view] && opts[:view][:host] || 8080
      @board = Board.new
      @board.build
    end

    def start
      EventMachine.run do
        trap("TERM") { stop }
        trap("INT")  { stop }


        EventMachine::start_server @host, @port, Connection::Client do |conn|
          conn.app = self
        end

        @channel  = EM::Channel.new

        EventMachine::start_server(@ws_host, @ws_port, Connection::WebSocket, :debug => @debug, :logging => true) do |ws|
            ws.app = self
            ws.onopen    {
              ws.sid = @channel.subscribe { |msg| ws.send msg }
              msg = "#{ws.display_name} just joined the game room"
              log msg, "WebSocket"
              @channel.push msg

              ws.onmessage { |msg|
                log msg, "WebSocket"
                @channel.push msg
              }

              ws.onclose   {
                msg = "#{ws.display_name} just left the game room"
                log msg, "WebSocket"
                @channel.push msg
                ws.send "Bye!"
              }
            }
        end

        log "Listening for clients on #{@host}:#{@port}"
        log "WebSocket server started on #{@ws_host}:#{@ws_port}"
      end
    end

    def stop
      log "Stopping server"
      EventMachine.stop
    end

    def current_move
    end

  end
end