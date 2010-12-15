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
            @app.new_visitor(self)
          when /PLAY/
            @app.play_game.succeed
          when /STOP/
            @app.stop_game.succeed
          when /JOIN/
            @app.new_player(self)
            @app.announce_player(self)
          when /LEAVE/
            @app.remove_player(self)
          when /OPPONENT\|/
            cmd, name = line.split(PIPE)
            @app.connect_opponent(name, self)
          when /MOVE\|\d \d \d/
            if has_turn?
              cmd, move = line.split(PIPE)
              @app.request_add_move.succeed(self, move)
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
        @app.remove_visitor(self)
      end

      protected

      def ensure_app
        raise "Instance of Sudocoup::Server not defined" unless @app
      end

    end
  end
end