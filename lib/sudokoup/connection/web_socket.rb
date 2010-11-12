module Sudokoup
  
  module Connection
    class WebSocket < EventMachine::WebSocket::Connection
      attr_accessor :app

      def receive_data(data)
        super(data)
        if line = data.slice!(/(.+)\r?\n/)
          case line
          when /NEW CONNECTION/
            json = %Q|{"action":"CREATE","values":#{@app.board.to_json}}|
            send(json)
          when /UPDATE/
            json = %Q|{"action":"UPDATE","value":#{@app.current_move.to_json}}|
            send(json)
          end
        end
      end

      protected

      def ensure_app
        raise "Instance of Sudokoup::Server not defined" unless @app
      end

    end
  end
end