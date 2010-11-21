module Sudokoup
  module Player
    class Socket < EventMachine::Connection
      include Sudokoup::StateMachine
      acts_as_state_machine :waiting, :playing, :has_turn

      attr_accessor :dispatch, :number

      def initialize(opts = {})
        waiting!
        @dispatch     = Dispatch.new
        @app          = opts[:app]
        @data = ''
      end

      def post_init
        log "initializing a connection..."
      end

      def receive_data(data)
        log data, @dispatch.name
        @data << data
        if line = @data.slice!(/(.+)\r?\n/).chomp
          action, response = @dispatch.call(line)
          case action
          when :send
            send response
          when :new_connection
            send response
          when :move
            @app.add_move.succeed(self, response)
          when :play
            @app.play_game.succeed
            @app.broadcast.succeed response
          when :close
            send response
            close_connection_after_writing
          end
        end
      end

      def close
        close_connection_after_writing
      end

      def unbind
        log "#{@dispatch.name} disconnected"
      end

      def send(text)
        send_data format(text)
      end

      def name
        @dispatch.name
      end

      def enter_game(number)
        @number = number
        playing!
      end

      protected

      def format(text)
        "#{text}\r\n"
      end

    end
  end

end