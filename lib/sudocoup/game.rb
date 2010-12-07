module Sudocoup
  class Game
    include Sudocoup::StateMachine
    has_states :waiting, :ready, :in_progress, :over

    attr_accessor :board, :state, :moves, :size
    attr_reader :players

    def initialize(opts = {})
      @size = opts[:size] || 2
      reset
    end

    def reset
      waiting!
      @players = []
      @board = Board.new
      @board.build
      @moves = []
    end

    def full?
      @players.size == @size
    end

    def available?
      !full? && waiting?
    end

    def play!
      raise "Game not ready for play" unless ready?
      in_progress!
      @players.each_with_index do |player, i|
        player.enter_game(i + 1)
        yield(player) if block_given?
      end
    end

    def status
      case state
      when :waiting
        "Waiting for more players"
      else
        "Game #{state.to_s}"
      end
    end

    def join_game(player)
      if joined = available?
        @players << player
        ready! if full?
      end
      joined
    end

    def add_player_move(player, move)
      return [:reject, "1 Not in the game, #{player.name}"] unless @players.include? player
      return [:reject, "2 Wait your turn, #{player.name}"] unless player.has_turn?

      if @board.add_move *move.split.map(&:to_i)
        player.stop_timer!
        [:ok, "#{player.name} played: #{move}"]
      elsif @board.violated?
        [:violation, "#{previous_player.name} WINS! #{player.name} played #{move} and violated the constraints"]
      else
        [:reject, "3 Illegal move. #{player.name} cannot play #{move}"]
      end
    end

    def add_move(x, y, value)
      @board.add_move(x, y, value)
    end

    def current_player
      @players.detect { |p| p.has_turn? }
    end

    def current_player_index
      @players.index(current_player)
    end

    def next_player
      return @players.first if current_player.nil?
      @players[current_player_index - @players.length + 1]
    end

    def previous_player
      return nil if current_player.nil?
      @players[current_player_index - 1]
    end

    def next_player!
      player = next_player
      @players.map(&:playing!)
      player.has_turn!
    end

    def send_players(msg)
      @players.each { |p| p.send(msg) }
    end

    def request_next_move(msg)
      next_player!
      current_player.send msg
      current_player.start_timer!
    end

    def times_up_violation(player)
      "#{previous_player.name} WINS! #{player.name} ran out of time!"
    end

  end

end