module Sudokl

  module App

    def self.start(opts = {})
      Server.new(opts).start
    end

    class Server

      def initialize(opts = {})
        @host = opts[:host] || '0.0.0.0'
        @port = opts[:port] || 44444
        @view_host = opts[:view] && opts[:view][:host] || '0.0.0.0'
        @view_port = opts[:view] && opts[:view][:port] || 55555
      end

      def start
        EventMachine.run do
          client_server = EventMachine::start_server @host, @port, ClientHandler
          view_server   = EventMachine::start_server @view_host, @view_port, ViewHandler

          puts "Listening for clients on #{@host}:#{@port}"
        end
      end

    end
  end
end