module Sudocoup
  module Client
    module ClientConnection
      # module ClassMethods
      # end
      # module InstanceMethods
      # end

      def self.included(base)
        # base.extend   ClassMethods
        # base.send :include, InstanceMethods
        base.send :include, Timer
        base.send :include, StateMachine

        base.has_states :waiting, :playing, :has_turn
        base.class_eval {
          attr_accessor :name, :number, :app
        }
      end

      def unbind
        super
        @app.call :remove_player, :player => self
        log "#{name} disconnected", SUDOKOUP
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

      def send_command(*args)
        send(*args)
      end

      def reset
        reset_time
        @moves = []
      end

    end
  end
end