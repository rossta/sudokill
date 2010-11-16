module Sudokoup
  class Game
    attr_accessor :board, :players, :state

    def self.acts_as_state_machine(*states)
      states.each do |state|
        class_eval <<-SRC
          def #{state.to_s.downcase}?
            @state == :#{state}
          end
        SRC
      end
    end
    acts_as_state_machine :waiting, :ready, :in_progress

    def initialize(opts = {})
      @num_players = opts[:num_players] || 2
      reset
    end

    def reset
      @state = :waiting
      @players = []
      @board = Board.new
      @board.build
    end

    def add_move(x, y, value)
      @board.add_move(x, y, value)
    end

    def full?
      @players.size == @num_players
    end

    def open?
      @players.size < @num_players
    end

    def in_progress?
      @state == :in_progress
    end

    def join_game(player)
      @players << player
      @state == :ready if full?
    end
  end

end