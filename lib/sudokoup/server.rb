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

        @server = EventMachine::start_server @host, @port, Player::Socket, :app => self do |player|
          connected.succeed(player)
        end

        EventMachine.add_periodic_timer(10) {
          @queue.each { |p| p.send("WAIT") }
        }

        EventMachine::start_server @ws_host, @ws_port, Player::WebSocket, :app => self,
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
      defer = EM::DefaultDeferrable.new
      defer.callback { |player, move|
        status, msg = @game.request_player_move(player, move)
        case status
        when :ok
          @channel.push %Q|{"action":"UPDATE","value":#{Move.new(*move.split).to_json},"status":"ok"}|
          @channel.push msg
        when :reject
          player.send ["REJECT", msg].join(" | ")
          @channel.push msg
        when :violation
          @channel.push %Q|{"action":"UPDATE","value":#{Move.new(*move.split).to_json},"status":"violation"}|
          @game.players.each { |p| p.send(["GAME OVER!", msg].join(" | ")) }
          new_game.succeed
        end
      }
      defer
    end

    def connected
      defer = EM::DefaultDeferrable.new
      defer.callback { |player|
        if @game.available?
          join_game player
        else
          join_queue player
        end
      }
      defer
    end

    def new_game
      defer = EM::DefaultDeferrable.new
      defer.callback {
        @game = Game.new
        while @game.available? && @queue.any?
          join_game @queue.shift
        end
        @channel.push board_json
      }
      defer
    end

    def join_game(player)
      joined = @game.join_game(player)
      if joined
        player.send("READY")
        @channel.push "Ready to begin" if @game.ready?
      end
      joined
    end

    def join_queue(player)
      @queue << player
      player.send("WAIT")
    end
    
    def board_json
      %Q|{"action":"CREATE","values":#{@game.board.to_json}}|
    end
  end
end