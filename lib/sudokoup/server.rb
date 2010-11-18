module Sudokoup
  class Server

    def self.start(opts = {})
      new(opts).start
    end

    attr_reader :game

    def initialize(opts = {})
      @host = opts[:host] || '0.0.0.0'
      @port = (opts[:port] || 44444).to_i
      @ws_host = '0.0.0.0'  # opts[:view] && opts[:view][:host] || '0.0.0.0'
      @ws_port = opts[:view] && (opts[:view][:port] || 8080).to_i

      @game     = Game.new
      @queue    = []
    end

    def start
      EventMachine.run do
        trap("TERM") { stop }
        trap("INT")  { stop }

        @channel  = EM::Channel.new

        @server = EventMachine::start_server @host, @port, Connection::Player, :app => self do |player|
          connected.succeed(player)
        end

        EventMachine.add_periodic_timer(10) {
          @queue.each { |p| p.send("WAIT") }
        }

        EventMachine::start_server @ws_host, @ws_port, Connection::WebSocket, :app => self,
          :debug => @debug, :logging => true do |ws|
            ws.onopen    {
              ws.sid = @channel.subscribe { |msg| ws.send msg }

              ws.onmessage { |msg|
                log msg, "WebSocket"

                if msg =~ /NEW CONNECTION/
                  type, name = msg.split("|")
                  ws.name = name.chomp
                  msg = "#{ws.display_name} just joined the game room"
                end

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

    def play_game
      play = EM::DefaultDeferrable.new
      play.callback {
        if @game.ready?
          @game.play!
        else
          @channel.push @game.status
        end
      }
      play
    end

    def add_move
      move = EM::DefaultDeferrable.new
      move.callback { |player, move|
        status, msg = @game.request_player_move(player, move)
        case status
        when :ok
          @channel.push %Q|{"action":"UPDATE","value":#{Move.new(*move.split).to_json}}|
          @channel.push msg
        when :error
          player.send msg
        when :game_over
          @game.players.each { |p| player send(msg) }
        end
      }
      move
    end

    def connected
      conn = EM::DefaultDeferrable.new
      conn.callback { |player|
        if @game.join_game(player)
          player.send("READY")
        else
          @queue << player
          player.send("WAIT")
        end
      }
      conn
    end
  end
end