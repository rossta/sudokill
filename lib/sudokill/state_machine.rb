module Sudokill
  module StateMachine
    def self.included(base)
      base.extend         ClassMethods
      base.class_eval {
        attr_accessor :sudokill_state
      }
    end

    module ClassMethods
      def has_states(*states)
        states.each do |state|
          state_name = state.to_s.downcase
          class_eval <<-SRC
            def #{state_name}?
              @sudokill_state == :#{state_name}
            end
            
            def #{state_name}!
              @sudokill_state = :#{state_name}
            end
          SRC
        end
      end
    end

  end
end