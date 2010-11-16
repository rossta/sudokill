module Sudokoup
  class Dispatch
    attr_accessor :app, :state

    # states: :waiting, :playing, :closed
    def initialize
      @name   = nil
      @state  = :waiting
    end

    def call(data)
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