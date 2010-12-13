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
          when /NEW CONNECTION/
            send @app.board_json
          when /PLAY/
            @app.play_game.succeed
          when /STOP/
            @app.stop_game.succeed
          when /^\d+ \d+ \d+$/
            @app.request_add_move.succeed(self, line)
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

      protected

      def ensure_app
        raise "Instance of Sudocoup::Server not defined" unless @app
      end

    end
  end
end