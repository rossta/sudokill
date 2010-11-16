module Sudokoup
  class Server

    def self.start(opts = {})
      new(opts).start
    end

    attr_reader :game

    def initialize(opts = {})
      @host = opts[:host] || '0.0.0.0'
      @port = opts[:port] || 44444
      @ws_host = opts[:view] && opts[:view][:host] || '0.0.0.0'
      @ws_port = opts[:view] && opts[:view][:host] || 8080
    end

    def start
      EventMachine.run do
        trap("TERM") { stop }
        trap("INT")  { stop }

        @channel  = EM::Channel.new
        @game     = Game.new
        @queue    = []
        
        entering  = EM::DefaultDeferrable.new
        entering.callback { |player|
          if @game.open?
            @game.join_game player
            player.send("READY")
          else
            @queue << player
            player.send("WAIT")
          end
        }

        @server = EventMachine::start_server @host, @port, Connection::Client, :app => self do |client|
          entering.succeed(client)
        end

        EventMachine.add_periodic_timer(5) {
          @channel.push @game.time if @game.in_progress?
          @queue.each { |p| p.send("WAIT") }
        }

        EventMachine::start_server @ws_host, @ws_port, Connection::WebSocket,
          :debug => @debug, :logging => true do |ws|
            ws.game = @game
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

  end
end