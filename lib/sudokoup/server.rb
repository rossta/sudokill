module Sudokoup
  class Server
    PIPE = " | "

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
          if @game.available?
            join_game player
          else
            join_queue player
          end
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
                #
                # if msg =~ /NEW CONNECTION/
                #   type, name = msg.split("|")
                #   ws.name = name.chomp
                #   msg = "#{ws.display_name} just joined the game room"
                # end
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
      @players.map(&:close)
      EventMachine.stop
    end

    def play_game
      defer = EM::DefaultDeferrable.new
      defer.callback {
        if @game.ready?
          @channel.push board_json
          @game.play!
          @game.players.each do |p|
            p.send start_message(p)
          end
        else
          @channel.push @game.status
        end
      }
      defer
    end

    def broadcast
      defer = EM::DefaultDeferrable.new
      defer.callback { |msg|
        @channel.push msg
      }
      defer
    end

    def add_move
      defer = EM::DefaultDeferrable.new
      defer.callback { |player, move|
        status, msg = @game.request_player_move(player, move)
        case status
        when :ok
          @channel.push move_json(move, status.to_s)
          @channel.push msg
          @game.current_player.send add_message(move)
        when :reject
          player.send reject_message(msg)
          @channel.push msg
        when :violation
          @channel.push move_json(move, status.to_s)
          @game.players.each { |p| p.send game_over_message(msg) }
          @game = Game.new
          while @game.available? && @queue.any?
            join_game @queue.shift
          end
        end
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

    def move_json(move, status)
      %Q|{"action":"UPDATE","value":#{Move.new(*move.split).to_json},"status":"#{status}"}|
    end

    def start_message(player)
      ["START", player.number, @game.board.to_msg].join(PIPE)
    end

    def reject_message(reason)
      ["REJECT", reason].join(PIPE)
    end
    
    def game_over_message(reason)
      ["GAME OVER", reason].join(PIPE)
    end
    
    def add_message(move)
      ["ADD", move, @game.board.to_msg].join(PIPE)
    end
  end
end