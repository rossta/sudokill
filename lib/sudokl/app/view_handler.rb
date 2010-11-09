module Sudokl

  module App

    class ViewHandler < EventMachine::Connection
      attr_accessor :app, :websocket

      def post_init
        log message("View connected")
      end

      def receive_data(data)
        log message("data received")
        (@buf ||= '') << data
        if line = @buf.slice!(/(.+)\r?\n/)
          case line
          when /NEW CONNECTION/
            json = %Q|{"action":"CREATE","values":#{@app.board.to_json}}|
            send_data(json + "\n")
          when /UPDATE/
            # json = %Q|{"action":"UPDATE","x":#{rand(9)}, "y":#{rand(9)}, "value":#{rand(9) + 1}}|
            json = %Q|{"action":"UPDATE","value":#{@app.current_move.to_json}}|
            send_data(json + "\n")
          end
        end
      end

      def unbind
        log message("View disconnected")
      end

      def message(response)
        "Server >> #{response}"
      end
      
      protected
      
      def ensure_app
        raise "Instance of Sudokl::App::Server not defined" unless @app
      end
    end

  end
end