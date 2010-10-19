module Sudokl

  module WebSocket
    
    def self.start(options, &block)
      server = EM.start_server(options[:host], options[:port],
        EventMachine::WebSocket::Connection, options) do |c|
        block.call(c)
      end
      puts "Sudokl WebSocket server started on #{options[:host]}:#{options[:port]}"
      server
    end
    
    def self.stop
      puts "Terminating WebSocket Server"
      EventMachine.stop
    end
  end

end