module Sudokoup

  module Player
    class WebSocket < EventMachine::WebSocket::Connection
      attr_accessor :app, :name, :sid

      def initialize(opts = {})
        super
        @app = opts[:app]
      end

      def receive_data(data)
        super(data)
        if line = data.slice!(/(.+)\r?\n/)
          case line
          when /NEW CONNECTION/
            send(app.board_json)
          when /PLAY/
            app.play_game.succeed
          end
        end
      end

      def display_name
        return @name if @name
        return "Visitor #{@sid}" if @sid
        "Anonymous Visitor"
      end

      def game
        @app.game
      end

      protected

      def ensure_app
        raise "Instance of Sudokoup::Server not defined" unless @app
      end

    end
  end
end