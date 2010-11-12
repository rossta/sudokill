module Sudokoup
  
  module Connection
    class Client < EventMachine::Connection
      attr_accessor :app

      def post_init
        @name = nil
        log "initializing a connection..."
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
          log response
          send_data("#{response}\r\n")
        end
      end

      def unbind
        log "#{@name} disconnected"
      end

    end
  end

end