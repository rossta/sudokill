# encoding: UTF-8

module Sudokill

  module Client
    class WebSocket < EventMachine::WebSocket::Connection
      include ClientConnection

      attr_accessor :sid, :conn

      def initialize(opts = {})
        super
        @app      = opts[:app]
        @max_time = opts[:max_time]
        @data     = ''

        @onmessage = method(:message_received).to_proc
      end

      def message_received(data)
        if line = data.slice!(/(.+)\r?\n/)
          line = line.chomp
          case line
          when /GET.*HTTP/
            log "New player connecting...", SUDOKILL
          when /NEW CONNECTION/
            log "New Connection...", SUDOKILL
            cmd, given_name = line.split(PIPE)
            @name = given_name
            @app.call :new_visitor, :visitor => self
          when /PLAY/
            @app.call :play_game, :density => convert_line_to_density(line)
          when /STOP/
            @app.call :stop_game
          when /SWITCH/
            @app.call :switch_controller, :visitor => self
          when /JOIN/
            @app.call :new_player, :player => self
            @app.call :announce_player, :player => self
          when /LEAVE/
            @app.call :remove_player, :player => self
          when /PREVIEW/
            @app.call :preview_board, :density => convert_line_to_density(line)
          when /OPPONENT\|/
            cmd, given_name = line.split(PIPE)
            @app.call :connect_opponent, :name => given_name, :visitor => self
          when /MOVE\|\d \d \d/
            if has_turn?
              cmd, move = line.split(PIPE)
              @app.call :request_add_move, :player => self, :move => move
            end
          else
            @app.broadcast line.gsub(/<\/?[^>]*>/, ""), display_name
          end
          log line, logger_name
        end
      end

      def name
        @name || 'WS Client'
      end

      def display_name
        name
      end

      def logger_name
        "WS[#{name || 'new'}]"
      end

      def send_command(*args)
        send(CommandJSON.to_json(*args))
      end

      def close
        send("Server disconnected")
      end

      def unbind
        super
        @app.call :remove_visitor, :visitor => self unless error?
      end

      def game_over!
        super
        send("Press 'Join game' to re-enter a game")
      end

      protected

      def convert_line_to_density(line)
        cmd, density = line.split(PIPE)
        (density.to_f/100)
      end

      def ensure_app
        raise "Instance of Sudokill::Server not defined" unless @app
      end

    end
  end
end