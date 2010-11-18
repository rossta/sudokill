module Sudokoup
  class Game
    attr_accessor :board, :state, :moves
    attr_reader :players

    def self.acts_as_state_machine(*states)
      states.each do |state|
        class_eval <<-SRC
          def #{state.to_s.downcase}?
            @state == :#{state}
          end
        SRC
      end
    end
    acts_as_state_machine :waiting, :ready, :in_progress, :over

    def initialize(opts = {})
      @num_players = opts[:num_players] || 2
      reset
    end

    def reset
      @state = :waiting
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
      @state == :in_progress
      @players.each do |p|
        p.send(@board.to_msg)
      end
    end

    def in_progress?
      @state == :in_progress
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
        @state = :ready if full?
      end
      joined
    end

    def request_player_move(player, move)
      return [:error, "#{player.name} is not currently playing"] unless @players.include? player
      return [:error, "It's not your turn, #{player.name}!"] unless player.turn?

      if @board.add_move *move.split.map(&:to_i)
        @moves << [player, move]
        msg = "#{player.name} played: #{move}"
        if @board.violated?
          [:game_over, [msg, "VIOLATION!", "#{previous_player(player).name} WINS!"].join(" ")]
        else
          [:ok, msg]
        end
      else
        [:error, "Move #{move} is not available"]
      end
    end

    def add_move(x, y, value)
      @board.add_move(x, y, value)
    end

    def previous_player(player)
      @players[@players.index(player) - 1]
    end

  end

end