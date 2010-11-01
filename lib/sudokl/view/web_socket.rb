module Sudokl

  module View

    module WebSocket

      def self.start(options, &block)
        server = EM.start_server(options.delete(:host), options.delete(:port),
          EventMachine::WebSocket::Connection, options) do |c|
          block.call(c)
        end
        log "Sudokl WebSocket server started on #{options[:host]}:#{options[:port]}"
        server
      end

      def self.stop
        log "Terminating WebSocket Server"
        EventMachine.stop
      end
    end

  end

end