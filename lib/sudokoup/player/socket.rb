module Sudokoup
  class Clock
    def self.time
      Time.now.to_i
    end
  end

  module Player
    class Socket < EventMachine::Connection
      include Sudokoup::StateMachine
      has_states :waiting, :playing, :has_turn

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
            @app.request_add_move.succeed(self, response)
          when :play
            @app.play_game.succeed
            @app.broadcast response
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

      attr_accessor :start_time, :stop_time, :last_lap, :total_time
      def start_timer!
        @start_time = Clock.time
      end

      def stop_timer!
        @stop_time = Clock.time
        @last_lap  = @stop_time - @start_time
        @total_time ||= 0
        @total_time += @last_lap
      end

      protected

      def format(text)
        "#{text}\r\n"
      end

    end
  end

end