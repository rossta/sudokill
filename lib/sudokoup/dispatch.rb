module Sudokoup
  class Dispatch
    attr_accessor :app, :state

    # states: :waiting, :playing, :closed
    def initialize
      @name   = nil
      @state  = :waiting
    end

    def call(data)
      if game.full?
        @state = :closed
        [:close, "Sorry. Game is full. Come back again soon"]
      end

      game.join_game(self)

      if @name.nil?
        @name = data
        [:send, "#{@name} now connected"]
      else
        [:send, "#{@name} said: #{data}"]
      end
    end

    def game
      @app.game
    end

    def name
      @name || 'Client'
    end
  end
end