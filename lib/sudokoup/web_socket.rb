module Sudokoup

  module WebSocket

    def self.start(options, &block)
      host = options.delete(:host)
      port = options.delete(:port)
      server = EM.start_server(host, port, EventMachine::WebSocket::Connection, options) do |c|
        block.call(c)
      end
      log "Sudokoup WebSocket server started on #{host}:#{port}"
      server
    end

    def self.stop
      log "Terminating WebSocket Server"
      EventMachine.stop
    end
  end

end