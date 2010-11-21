module Sudokoup
  class Game
    include Sudokoup::StateMachine
    acts_as_state_machine :waiting, :ready, :in_progress, :over

    attr_accessor :board, :state, :moves
    attr_reader :players

    def initialize(opts = {})
      @num_players = opts[:num_players] || 2
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
      @players.size == @num_players
    end

    def available?
      !full? && waiting?
    end

    def play!
      raise "Game not ready for play" unless ready?
      in_progress!
      @players.each_with_index do |player, i|
        player.enter_game(i + 1)
      end
    end

    def status
      case state
      when :waiting
        "Game waiting for more players"
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

    def request_player_move(player, move)
      return [:reject, "Not in the game, #{player.name}"] unless @players.include? player
      return [:reject, "Wait your turn, #{player.name}"] unless player.has_turn?

      if @board.add_move *move.split.map(&:to_i)
        [:ok, "#{player.name} played: #{move}"]
      elsif @board.violated?
        [:violation, "#{player.name} played: #{move} and violated the constraints!"]
      else
        [:reject, "Illegal move. #{player.name} cannot play #{move}"]
      end
    end

    def add_move(x, y, value)
      @board.add_move(x, y, value)
    end

    def previous_player(player)
      @players[@players.index(player) - 1]
    end

    def current_player
      @players.detect { |p| p.has_turn? }
    end

  end

end