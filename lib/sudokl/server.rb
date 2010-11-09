module Sudokl
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
      board.build
    end

    def start
      EventMachine.run do
        trap("TERM") { Sudokl::WebSocket.stop }
        trap("INT")  { Sudokl::WebSocket.stop }

        EventMachine::start_server @host, @port, ClientHandler do |handler|
          handler.app = self
        end

        EM.start_server @view_host, @view_port, ViewHandler do |handler|
          handler.app = self
        end

        @proxy = EM.connect @view_host, @view_port, Sudokl::Proxy

        Sudokl::WebSocket.start(:host => "0.0.0.0", :port => @sock, :debug => @debug, :logging => true) do |ws|
          ws.onopen    {
            @proxy.websocket = ws
          }

          ws.onmessage { |msg|
            @proxy.send_data(msg)
          }

          ws.onclose   {
            ws.send "Closing time"
            log "WebSocket closed"
          }

        end


        log "Listening for clients on #{@host}:#{@port}"
      end
    end

  end
end