module Sudokoup

  module Connection
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
            json = %Q|{"action":"CREATE","values":#{game.board.to_json}}|
            send(json)
          when /UPDATE/
            json = %Q|{"action":"UPDATE","value":#{game.current_move.to_json}}|
            send(json)
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