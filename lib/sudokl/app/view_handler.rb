module Sudokl
  
  module App
    
    class ViewHandler < EventMachine::Connection
      def post_init
        puts message "View connected"
      end

      def receive_data(data)
        (@buf ||= '') << data
        if line = @buf.slice!(/(.+)\r?\n/)
          case line
          when /NEW CONNECTION/
            board = Board.new
            board.build
            json = %Q|{"action":"CREATE","values":#{board.to_json}}|
            send_data(json + "\n")
          when /UPDATE/
            json = %Q|{"action":"UPDATE","x":#{rand(9)}, "y":#{rand(9)}, "value":#{rand(9) + 1}}|
            send_data(json + "\n")
          end
        end
      end

      def unbind
        puts message "View disconnected"
      end

      def message(response)
        "Server >> #{response}"
      end
    end
    
  end
end