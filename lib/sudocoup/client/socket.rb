module Sudocoup

  module Client
    class Socket < EventMachine::Connection
      include ClientConnection

      attr_accessor :dispatch

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
        if line = @data.slice!(/(.+)\r?\n/)
          line = line.chomp
          action, response = @dispatch.call(line)
          case action
          when :send
            send response
          when :new_connection
            @app.call :announce_player, :player => self
          when :move
            @app.call :request_add_move, :player => self, :move => response
          when :play
            @app.call :play_game
            @app.broadcast response
          when :close
            send response
            close_connection_after_writing
          end
          # log line, logger_name
        end
      end

      def close
        close_connection_after_writing
      end

      def send(text)
        send_data format(text)
      end

      def name
        @name ||= @dispatch.name
      end
      
      def logger_name
        "SK[#{name}]"
      end
      
      def time_left?(max_time = nil)
        max_time.nil? || current_time <= max_time
      end

      protected

      def format(text)
        "#{text}\r\n"
      end

    end
  end

end