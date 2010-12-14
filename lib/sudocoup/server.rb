module Sudocoup
  PIPE = "|"
  SUDOKOUP = 'Sudocoup'

  class Server

    def self.start(opts = {})
      new(opts).start
    end

    attr_reader :game, :queue
    attr_accessor :max_time, :channel

    def initialize(opts = {})
      @host     = opts[:host] || '0.0.0.0'
      @port     = (opts[:port] || 44444).to_i
      @ws_host  = '0.0.0.0'
      @ws_port  = (opts[:ws_port] || 8080).to_i
      @opts     = opts

      @game     = Game.new(:size => @opts[:size], :config => @opts[:config])
      @queue    = []
      @max_time = (opts[:max_time]).to_i if opts[:max_time]
    end

    def start
      EventMachine.run do
        trap("TERM") { stop }
        trap("INT")  { stop }

        @channel  = EM::Channel.new

        EventMachine::start_server @host, @port, Client::Socket, :app => self do |player|
          new_player player
        end

        EventMachine.add_periodic_timer(0.25) {
          if @game.in_progress?
            if !time_left?(@game.current_player)
              end_game(@game.times_up_violation(@game.current_player))
            end
            broadcast(player_json) if players.any?
          end
        }

        EventMachine::start_server @ws_host, @ws_port, Client::WebSocket, :app => self,
          :debug => @debug, :logging => true do |ws|
            ws.onopen { ws.sid = @channel.subscribe { |msg| ws.send msg } }
        end

        log_server_started
      end
    end

    def stop
      log "Stopping server"
      players.map(&:close)
      queue.map(&:close)
      EventMachine.stop
    end

    def players
      @game.players
    end

    def play_game
      defer = EM::DefaultDeferrable.new
      defer.callback {
        if @game.players.any? && @game.ready?
          broadcast board_json
          broadcast status_json("New game about to begin!")
          @game.play! do |player|
            send_player_message(player, start_message(player))
          end
          request_next_player_move
        else
          broadcast status_json(@game.status)
        end
      }
      defer
    end

    def stop_game
      defer = EM::DefaultDeferrable.new
      defer.callback {
        if @game.in_progress?
          end_game("Game stopped!")
        else
          broadcast status_json(@game.status)
        end
      }
      defer
    end

    def broadcast(msg, name = nil)
      return if @channel.nil?
      msg = "#{name}: #{msg}" unless name.nil?
      @channel.push msg
    end

    def request_add_move
      defer = EM::DefaultDeferrable.new
      defer.callback { |player, move|
        status, msg = @game.add_player_move(player, move)
        played_move = Move.build(move, player.number)
        case status
        when :ok
          broadcast move_json(played_move, status.to_s)
          broadcast msg, SUDOKOUP
          send_players(move)
          sleep 1.0
          request_next_player_move
        when :reject
          send_player_message(player, reject_message(msg))
          broadcast msg, SUDOKOUP
        when :violation
          broadcast move_json(played_move, status.to_s)
          end_game(msg)
        end
      }
      defer
    end

    def new_player(player)
      if @game.available?
        join_game player
      else
        join_queue player
      end
    end

    def new_visitor(visitor)
      visitor.send status_json("Welcome to Sudocoup, #{visitor.name}")
      visitor.send board_json
      visitor.send player_json
      visitor.send queue_json
      msg = "#{visitor.name} just joined the game room"
      broadcast msg, SUDOKOUP
      log msg, SUDOKOUP
    end

    def remove_visitor(visitor)
      visitor.send "Bye!"
      msg = "#{visitor.name} just left the game room"
      broadcast msg, SUDOKOUP
      log msg, SUDOKOUP
    end

    def remove_player(player)
      if @game.players.delete(player)
        case @game.sudocoup_state
        when :in_progress
          end_game("#{player.name} left the game")
          return
        when :waiting, :ready
          @game.waiting!        if @game.ready?
          add_player_from_queue if @queue.any?
        end
        broadcast "#{player.name} left the game", SUDOKOUP
      elsif @queue.delete(player)
        broadcast("#{player.name} left the On Deck circle", SUDOKOUP)
      else
      end
      broadcast player_json
      broadcast queue_json
      log "#{player.name} disconnected", SUDOKOUP
    end

    def join_game(player)
      joined = @game.join_game(player)
      if joined
        player.reset
        send_player_message(player, "READY")
        broadcast("Ready to begin", SUDOKOUP) if @game.ready?
      end
      joined
    end

    def join_queue(player)
      @queue << player
      send_player_message(player, "WAIT")
    end

    def announce_player(player)
      if @game.has_player? player
        broadcast("#{player.name} is now in the game", SUDOKOUP)
      elsif @queue.include? player
        broadcast("#{player.name} is now waiting On Deck", SUDOKOUP)
      end
      broadcast player_json
      broadcast queue_json
    end

    def request_next_player_move
      @game.next_player_request do |player|
        send_player_message(player, add_message)
      end
      broadcast status_json "#{@game.current_player.name}'s turn!"
    end

    def time_left?(player)
      return true if max_time.nil?
      player.current_time <= max_time
    end

    def end_game(msg)
      @game.over!
      send_players game_over_message(msg)
      broadcast msg
      broadcast status_json(msg)
      new_game
    end

    def new_game
      @game = Game.new(:size => @opts[:size], :config => @opts[:config])
      while @game.available? && @queue.any?
        add_player_from_queue
      end
    end

    def add_player_from_queue
      player = @queue.shift
      join_game player
      announce_player player
    end

    def send_players(msg)
      players.each { |player| send_player_message(player, msg) }
    end

    def send_player_message(player, msg)
      player.send_command msg
    end

    def connect_opponent(name, visitor)
      id = rand(100)
      case name.downcase.to_sym
      when :naive
        EM.connect(@host, @port, Player::Naive, :name => name)
      when :easy, :medium, :hard
        fork do
          system("cd bin/Vincent/; java Sudokill_#{name} #{host_name(@host)} #{@port} #{name}#{id}")
        end
      when :simon
        fork do
          system("cd bin/Simon/; java Main")
        end
      else
        visitor.send("Didn't recognize opponent, #{name}", SUDOKOUP)
      end
    end

    def board_json
      BoardJSON.to_json(@game.board)
    end

    def move_json(move, status)
      MoveJSON.to_json(move, status)
    end

    def player_json
      PlayerJSON.to_json(players, max_time)
    end

    def queue_json
      QueueJSON.to_json(queue)
    end

    def status_json(message)
      StatusJSON.to_json(@game.sudocoup_state, message)
    end

    def game_over_json
      GameOverJSON.to_json(players)
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