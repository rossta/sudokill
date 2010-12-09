module Sudocoup
  class Clock
    def self.time
      Time.now.to_i
    end
  end

  module Player
    class Socket < EventMachine::Connection
      include Sudocoup::StateMachine
      has_states :waiting, :playing, :has_turn

      attr_accessor :dispatch, :number, :name

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
        @app.remove_player(self)
        log "#{@dispatch.name} disconnected"
      end

      def send(text)
        send_data format(text)
      end

      def name
        @name ||= @dispatch.name
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
          arr << [%Q|"max_time"|, max_time]
          arr << [%Q|"has_turn"|, has_turn?]
        end
        %Q|{#{attrs.map { |a| a.join(":") }.join(",") } }|
      end

      attr_accessor :start_time, :stop_time, :last_lap, :total_time
      def total_time
        @total_time ||= 0
      end

      def current_time
        unless @start_time.nil?
          Clock.time - @start_time + total_time
        else
          total_time
        end
      end

      def start_timer!
        @start_time = Clock.time
      end

      def stop_timer!
        @stop_time = Clock.time
        @last_lap  = @stop_time - @start_time
        @start_time = nil
        total_time
        @total_time += @last_lap
      end

      def max_time
        120 # TODO add as option to app
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