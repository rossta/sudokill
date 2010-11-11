module Sudokoup
  class Server

    def self.start(opts = {})
      new(opts).start
    end

    attr_reader :board

    def initialize(opts = {})
      @host = opts[:host] || '0.0.0.0'
      @port = opts[:port] || 44444
      @sock = opts[:sock] || 8080
      @view_host = opts[:view] && opts[:view][:host] || '0.0.0.0'
      @view_port = opts[:view] && opts[:view][:port] || 45454
      @board = Board.new
      @board.build
    end

    def start
      EventMachine.run do
        trap("TERM") { Sudokoup::WebSocket.stop }
        trap("INT")  { Sudokoup::WebSocket.stop }


        EventMachine::start_server @host, @port, ClientHandler do |handler|
          handler.app = self
        end

        EventMachine::start_server @view_host, @view_port, ViewHandler do |handler|
          handler.app = self
        end

        @channel  = EM::Channel.new
        @proxy    = EM.connect @view_host, @view_port, Sudokoup::Proxy

        Sudokoup::WebSocket.start(:host => "0.0.0.0", :port => @sock, :debug => @debug, :logging => true) do |ws|
          ws.onopen    {
            @proxy.websocket = ws

            sid = @channel.subscribe { |msg| ws.send msg }
            msg = "Visitor #{sid} connected!"
            @channel.push msg
            log msg, "WebSocket"

            ws.onmessage { |msg|
              log "Message: #{msg}", "WebSocket"
              @proxy.send_data(msg)
            }

            ws.onclose   {
              ws.send "Bye!"
              log "Visitor #{sid} disconnected", "WebSocket"
            }
          }


        end

        log "Listening for clients on #{@host}:#{@port}"
      end
    end

    def current_move
    end

  end
end