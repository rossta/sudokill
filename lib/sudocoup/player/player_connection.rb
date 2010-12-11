module Sudocoup
  module Player
    module PlayerConnection
      # module ClassMethods
      # end
      # module InstanceMethods
      # end

      def self.included(base)
        # base.extend   ClassMethods
        # base.send :include, InstanceMethods
        base.send :include, Timer
        base.send :include, Timer
        base.send :include, StateMachine

        base.has_states :waiting, :playing, :has_turn
        base.class_eval {
          attr_accessor :name, :number, :app
        }
      end
      
      def unbind
        @app.remove_player(self)
        log "#{name} disconnected"
      end
      
    end
  end
end