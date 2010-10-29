module Sudokl
  
  module App
    
    class ClientHandler < EventMachine::Connection
      def post_init
        @name = nil
        puts message("someone connected")
      end

      def receive_data(data)
        (@buf ||= '') << data
        if line = @buf.slice!(/(.+)\r?\n/)
          if @name.nil?
            @name = line.chomp
            response = "#{@name} now connected"
          else
            response = "#{@name} said: #{line}"
          end
        end
        if response
          puts message(response)
          send_data("#{response}\r\n")
        end
      end

      def unbind
        puts message "#{@name} disconnected"
      end

      def message(response)
        "Echo >> #{response}"
      end
    end
    
  end
end