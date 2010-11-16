module Sudokoup
  class Game
    attr_accessor :board
    def initialize(opts = {})
      @num_players = opts[:num_players] || 2

      reset
    end
    
    def reset
      @players = []
      @board = Board.new
      @board.build
    end
    
    def add_move(x, y, value)
      @board.add_move(x, y, value)
    end
    
    def full?
      @num_players == @players.size
    end
    
    def join_game(player)
      @players << player
    end
  end
  
end