module Sudokoup
  PIPE = "|"
  SUDOKOUP = 'Sudokoup'

  class Server

    def self.start(opts = {})
      new(opts).start
    end

    attr_reader :game, :queue

    def initialize(opts = {})
      @host     = opts[:host] || '0.0.0.0'
      @port     = (opts[:port] || 44444).to_i
      @ws_host  = '0.0.0.0'
      @ws_port  = (opts[:ws_port] || 8080).to_i

      @game     = Game.new
      @queue    = []
    end

    def start
      EventMachine.run do
        trap("TERM") { stop }
        trap("INT")  { stop }

        @channel  = EM::Channel.new

        EventMachine::start_server @host, @port, Player::Socket, :app => self do |player|
          if @game.available?
            join_game player
          else
            join_queue player
          end
        end

        # EventMachine.add_periodic_timer(10) {
        #   @queue.each { |p| p.send("WAIT") }
        # }

        EventMachine::start_server @ws_host, @ws_port, Player::WebSocket, :app => self,
          :debug => @debug, :logging => true do |ws|
            ws.onopen    {
              ws.sid = @channel.subscribe { |msg|
                ws.send msg
              }

              ws.onmessage { |msg|
                if msg =~ /NEW CONNECTION/
                  type, name = msg.split(PIPE)
                  ws.name = name.chomp
                  broadcast "#{ws.name} just joined the game room", SUDOKOUP
                else
                  broadcast msg, ws.name
                end
              }

              ws.onclose   {
                msg = "#{ws.name} just left the game room"
                log msg, ws.logger_name
                broadcast msg, SUDOKOUP
                ws.send "Bye!"
              }
            }
        end

        log_server_started
      end
    end

    def stop
      log "Stopping server"
      @queue.map(&:close)
      EventMachine.stop
    end

    def players
      @game.players
    end

    def play_game
      defer = EM::DefaultDeferrable.new
      defer.callback {
        if @game.ready?
          broadcast board_json
          @game.play! do |player|
            player.send start_message(player)
          end
          request_next_player_move
        else
          broadcast @game.status, SUDOKOUP
        end
      }
      defer
    end

    def broadcast(msg, name = nil)
      msg = "#{name}: #{msg}" unless name.nil?
      @channel.push msg
    end

    def request_add_move
      defer = EM::DefaultDeferrable.new
      defer.callback { |player, move|
        status, msg = @game.add_player_move(player, move)
        case status
        when :ok
          broadcast move_json(move, status.to_s)
          broadcast msg, SUDOKOUP
          @game.send_players(move)
          request_next_player_move
        when :reject
          player.send reject_message(msg)
          broadcast msg, SUDOKOUP
        when :violation
          broadcast move_json(move, status.to_s)
          @game.send_players game_over_message(msg)
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
        broadcast("Ready to begin", SUDOKOUP) if @game.ready?
      end
      joined
    end

    def join_queue(player)
      @queue << player
      player.send("WAIT")
    end

    def request_next_player_move
      @game.next_player!
      @game.current_player.send add_message
    end

    def board_json
      %Q|{"action":"CREATE","values":#{@game.board.to_json}}|
    end

    def move_json(move, status)
      %Q|{"action":"UPDATE","value":#{Move.new(*move.split).to_json},"status":"#{status}"}|
    end

    def start_message(player)
      ["START", player.number, @game.size, @game.board.to_msg].join(PIPE)
    end

    def reject_message(reason)
      ["REJECT", reason].join(PIPE)
    end

    def game_over_message(reason)
      ["GAME OVER", reason].join(PIPE)
    end

    def add_message
      ["ADD", @game.board.to_msg].join(PIPE)
    end

    protected

    def log_server_started
      log "Listening for players on #{host_name(@host)}:#{@port}"
      log "Listening for websockets at ws://#{host_name(@ws_host)}:#{@ws_port}"
    end

    def host_name(host)
      host == "0.0.0.0" ? 'localhost' : host
    end
  end
end