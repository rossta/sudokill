module Sudokl

  module App

    def self.start(opts = {})
      host = opts[:host] || '0.0.0.0'
      port = opts[:port] || 44444

      EventMachine.run do
        EventMachine::start_server host, port, Echo
        puts "Started Sodukl::Server::Echo on #{host}:#{port}"
      end

    end

    class Echo < EventMachine::Connection
      def post_init
        @name = nil
        puts message("someone connected")
      end

      def receive_data(data)
        (@buf ||= '') << data
        if line = @buf.slice!(/(.+)\r?\n/)
          if @name.nil?
            @name = line.chomp
            response = "#{@name} now connected"
          else
            response = "#{@name} said: #{line}"
          end
        end
        if response
          puts message(response)
          send_data("#{response}\r\n")
        end
      end

      def unbind
        puts message "#{@name} disconnected"
      end

      def message(response)
        "Echo >> #{response}"
      end
    end

    class Base

      def initialize(opts = {})
        @host = opts[:host] || '127.0.0.1'
        @port = opts[:port] || 44444
      end

      def connect!
        begin
          @server = TCPServer.new(@host, @port)

          puts "Waiting for client on port #{@port}"
          client = @server.accept
          client.puts "Welcome"
          puts client.readline
          while message = STDIN.gets
            client.puts message
            puts client.readline
          end
          client.close

        rescue Exception => e
          puts e.message
        end
      end

    end

  end

end