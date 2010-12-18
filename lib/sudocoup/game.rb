module Sudocoup
  class Game
    include Sudocoup::StateMachine
    has_states :waiting, :ready, :in_progress, :over

    attr_accessor :board, :moves, :size
    attr_reader :players

    def initialize(opts = {})
      @size = opts[:size] || 2
      @file = opts[:file] || "data/1.sud"
      reset
    end

    def reset
      waiting!
      @players = []
      @board = Board.from_file(@file, 0.33)
      @moves = []
    end

    def has_player?(player)
      @players.include?(player)
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
      case sudocoup_state
      when :waiting
        "Waiting for more players"
      else
        "Game #{sudocoup_state.to_s}"
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

      player.stop_timer!
      move_to_i = move.split.map(&:to_i)
      if add_move_to_board *move_to_i
        player.add_move *move_to_i
        [:ok, "#{player.name} played: #{move}"]
      else
        [:violation, "#{previous_player.name} WINS! #{player.name} played #{move}: #{@board.error}"]
      end
    end

    def add_move_to_board(row, col, val)
      @board.add_move(row, col, val)
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

    def next_player_request
      next_player!
      yield current_player if block_given?
      current_player.start_timer!
    end

    def times_up_violation(player)
      "#{previous_player.name} WINS! #{player.name} ran out of time!"
    end

  end

end