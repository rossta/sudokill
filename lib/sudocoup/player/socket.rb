module Sudocoup

  module Player
    class Socket < EventMachine::Connection
      include PlayerConnection

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
        if line = @data.slice!(/(.+)\r?\n/).chomp
          action, response = @dispatch.call(line)
          case action
          when :send
            send response
          when :new_connection
            @app.announce_player(self)
          when :move
            @app.request_add_move.succeed(self, response)
          when :play
            @app.play_game.succeed
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

      protected

      def format(text)
        "#{text}\r\n"
      end

    end
  end

end