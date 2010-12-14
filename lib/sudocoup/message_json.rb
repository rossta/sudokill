module Sudocoup
  class MessageJSON
    def self.to_json(*args)
      new(*args).to_json
    end
    def action
      raise "implemented by subclasses"
    end
    def to_json
      attrs = { :action => json_string(action) }.merge(json_args)
      json = [].tap { |j| attrs.each { |k,v| j << %Q|"#{k}":#{v}| } }
      %Q|{#{json.join(',')}}|
    end
    def json_args
      {}
    end
    def json_string(text)
      %Q|"#{text}"|
    end
  end
  
  class BoardJSON < MessageJSON
    def initialize(board)
      @board = board
    end
    def action
      "CREATE"
    end
    def json_args
      { :values => @board.to_json }
    end
  end
  
  class MoveJSON < MessageJSON
    def initialize(move,status)
      @move   = move
      @status = status
    end
    def action
      "UPDATE"
    end
    def json_args
      { :value => @move.to_json, :status => json_string(@status) }
    end
  end
  
  class PlayerJSON < MessageJSON
    def initialize(players, max_time = nil)
      @players = players
      @max_time = max_time
    end
    def action
      "SCORE"
    end
    def json_args
      {}.tap do |args|
        args[:players] = "[#{@players.map(&:to_json).join(",")}]"
        args[:max_time] = @max_time unless @max_time.nil?
      end
    end
  end
  
  class QueueJSON < MessageJSON
    def initialize(queue)
      @queue = queue
    end
    def action
      "QUEUE"
    end
    def json_args
      { :players => "[#{@queue.map(&:to_json).join(",")}]" }
    end
  end
  
  class StatusJSON < MessageJSON
    def initialize(state, message)
      @state   = state
      @status  = message
    end
    def action
      "STATUS"
    end
    def json_args
      { :state => json_string(@state), :message => json_string(@status) }
    end
  end
  
  class CommandJSON < MessageJSON
    def initialize(command)
      @command = command
    end
    def action
      "COMMAND"
    end
    def json_args
      { :command => json_string(@command) }
    end
  end
  
  class GameOverJSON < MessageJSON
    def initialize(players)
      @players = players
    end
    def action
      "GAMEOVER"
    end
    def json_args
      { :players => "[#{@players.map(&:to_json).join(",")}]" }
    end
  end
end