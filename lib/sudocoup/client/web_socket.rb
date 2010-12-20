module Sudocoup

  module Client
    class WebSocket < EventMachine::WebSocket::Connection
      include ClientConnection

      attr_accessor :sid, :conn

      def initialize(opts = {})
        super
        @app      = opts[:app]
        @data     = ''
      end

      def receive_data(data)
        super(data)
        if line = data.slice!(/(.+)\r?\n/)
          line = line.chomp
          case line
          when /GET.*HTTP/
            log "New player connecting...", SUDOKOUP
          when /NEW CONNECTION/
            cmd, name = line.split(PIPE)
            @name = name
            @app.call :new_visitor, :visitor => self
          when /PLAY/
            cmd, density = line.split(PIPE)
            @app.call :play_game, :density => (density.to_f/100)
          when /STOP/
            @app.call :stop_game
          when /SWITCH/
            @app.call :switch_controller, :visitor => self
          when /JOIN/
            @app.call :new_player, :player => self
            @app.call :announce_player, :player => self
          when /LEAVE/
            @app.call :remove_player, :player => self
          when /OPPONENT\|/
            cmd, name = line.split(PIPE)
            @app.call :connect_opponent, :name => name, :visitor => self
          when /MOVE\|\d \d \d/
            if has_turn?
              cmd, move = line.split(PIPE)
              @app.call :request_add_move, :player => self, :move => move
            end
          else
            @app.broadcast line, name
          end
          log line, logger_name
        end
      end

      def name
        @name || 'WS Client'
      end

      def logger_name
        "WS[#{name || 'new'}]"
      end

      def send_command(*args)
        send(CommandJSON.to_json(*args))
      end

      def close
        send("Server disconnected")
      end

      def unbind
        super
        @app.call :remove_visitor, :visitor => self
      end

      protected

      def ensure_app
        raise "Instance of Sudocoup::Server not defined" unless @app
      end

    end
  end
end