module Sudokoup
  class Dispatch
    attr_accessor :app, :name

    def initialize
      @name   = nil
    end

    def call(data)
      if @name.nil?
        @name = data
        [:new_connection, "#{@name} now connected"]
      else
        case data
        when /^\d+ \d+ \d+$/
          [:move, data]
        when /^PLAY$/
          [:play, "New game about to begin!"]
        else
          [:send, "#{@name} said: #{data}"]
        end
      end
    end

    def name
      @name || 'Client'
    end
  end
end