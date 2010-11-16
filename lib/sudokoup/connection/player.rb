module Sudokoup
  module Connection
    class Player < EventMachine::Connection
      attr_accessor :app

      def initialize(opts = {})
        @dispatch     = Dispatch.new
        @dispatch.app = opts[:app]
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
          when :close
            send response
            close_connection_after_writing
          end
        end
      end

      def unbind
        log "#{@dispatch.name} disconnected"
      end
      
      def send(text)
        send_data format(text)
      end
      
      protected

      def format(text)
        "#{text}\r\n"
      end
      
    end
  end

end