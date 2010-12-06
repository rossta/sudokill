module Sudocoup

  module Player
    class WebSocket < EventMachine::WebSocket::Connection
      attr_accessor :app, :name, :sid, :number

      def initialize(opts = {})
        super
        @app      = opts[:app]
        @data     = ''
      end

      def receive_data(data)
        super(data)
        if line = data.slice!(/(.+)\r?\n/)
          case line
          when /NEW CONNECTION/
            send @app.board_json
          when /PLAY/
            @app.play_game.succeed
          when /^\d+ \d+ \d+$/
            @app.request_add_move.succeed(self, response)
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