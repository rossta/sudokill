module Sudokoup

  module Connection
    class Client < EventMachine::Connection
      attr_accessor :game, :name

      def post_init
        log "initializing a connection..."
      end

      def receive_data(data)
        if @game.full?
          send_data "Sorry. Game is full. Come back again soon"
          close_connection_after_writing
          return
        end

        @game.join_game(self)

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