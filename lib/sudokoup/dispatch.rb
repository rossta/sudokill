module Sudokoup
  class Dispatch
    attr_accessor :app, :name

    def initialize
      @name   = nil
    end

    def call(data)
      if @name.nil?
        @name = data
        [:send, "#{@name} now connected"]
      else
        case data
        when /^\d+ \d+ \d+$/
          [:move, data]
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