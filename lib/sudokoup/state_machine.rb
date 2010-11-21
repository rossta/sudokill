module Sudokoup
  module StateMachine
    def self.included(receiver)
      receiver.extend         ClassMethods
      # receiver.send :include, InstanceMethods
    end

    module ClassMethods
      def acts_as_state_machine(*states)
        states.each do |state|
          state_name = state.to_s.downcase
          class_eval <<-SRC
            def #{state_name}?
              @state == :#{state_name}
            end
            
            def #{state_name}!
              @state = :#{state_name}
            end
          SRC
        end
      end
    end

    # module InstanceMethods
    #
    # end

  end
end