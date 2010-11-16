module Sudokoup
  
  module Connection
    class WebSocket < EventMachine::WebSocket::Connection
      attr_accessor :game, :name, :sid

      def receive_data(data)
        super(data)
        if line = data.slice!(/(.+)\r?\n/)
          case line
          when /NEW CONNECTION/
            json = %Q|{"action":"CREATE","values":#{@game.board.to_json}}|
            send(json)
          when /UPDATE/
            json = %Q|{"action":"UPDATE","value":#{@game.current_move.to_json}}|
            send(json)
          end
        end
      end
      
      def display_name
        return @name if @name
        return "Visitor #{@sid}" if @sid
        "Anonymous Visitor"
      end

      protected

      def ensure_app
        raise "Instance of Sudokoup::Server not defined" unless @app
      end

    end
  end
end