module Sudokoup

  module Player
    class WebSocket < EventMachine::WebSocket::Connection
      attr_accessor :app, :name, :sid, :number

      def initialize(opts = {})
        super
        @dispatch = Dispatch.new
        @app      = opts[:app]
        @data     = ''
      end

      def receive_data(data)
        super(data)
        if line = @data.slice!(/(.+)\r?\n/).chomp
          action, response = @dispatch.call(line)
          case action
          when :send
            send response
          when :new_connection
            send app.board_json
            send response
          when :play
            @app.play_game.succeed
            @app.broadcast.succeed response
          when :move
            @app.add_move.succeed(self, response)
          when :close
            send response
          end
        end
      end

      def display_name
        return @name if @name
        return "Visitor #{@sid}" if @sid
        "Anonymous Visitor"
      end

      def name
        @dispatch.name
      end

      protected

      def ensure_app
        raise "Instance of Sudokoup::Server not defined" unless @app
      end

    end
  end
end