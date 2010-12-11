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
          log line, logger_name
        end
      end

      def close
        close_connection_after_writing
      end

      def unbind
        @app.remove_player(self)
        log "#{name} disconnected"
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

      def enter_game(number)
        @number = number
        playing!
      end

      def to_json
        attrs = [].tap do |arr|
          arr << [%Q|"name"|, %Q|"#{name}"|]
          arr << [%Q|"number"|, number] unless @number.nil?
          arr << [%Q|"moves"|, moves.size]
          arr << [%Q|"current_time"|, current_time]
          arr << [%Q|"has_turn"|, has_turn?]
        end
        %Q|{#{attrs.map { |a| a.join(":") }.join(",") } }|
      end

      def moves
        @moves ||= []
      end

      def add_move(row, col, val)
        moves << Move.new(row, col, val)
      end

      protected

      def format(text)
        "#{text}\r\n"
      end

    end
  end

end