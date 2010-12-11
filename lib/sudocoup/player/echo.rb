module Sudocoup
  module Player
    class Echo < EventMachine::Connection
      include EM::Deferrable
      
      def initialize(options = {})
        @name = options[:name]
        @stop = options[:stop]
        @data = ''
      end

      def post_init
        send @name
      end

      def receive_data(data)
        @data << data
        # puts "data: #{data.chomp}"
        while line = @data.slice!(/(.+)\r?\n/)
          puts "Server >> #{line.chomp}"
          case line
          when /^GAME OVER/
            close_connection_after_writing
            @stop.call
          end
        end
      end

      def send(text)
        send_data format(text)
      end

      def format(text)
        "#{text}\r\n"
      end
      
      def self.play!(name, host, port)
         EM.run {
           @queue = []
           stop = proc {
             EM.stop
             puts "Bye"
           }
           trap("TERM") { stop.call }
           trap("INT") { stop.call }

           client = EM.connect host, port, Sudocoup::Player::Echo, :name => name, :stop => stop

           client.callback { |text|
             client.send text
           }
           client.errback {
             puts "Something went wrong!"
           }

           read_and_write = proc {
             EM.defer(proc {
               line = STDIN.gets
               line = line.chomp
               @queue << line
               line
             }, proc { |text|
               line = @queue.shift
               client.send line unless line.nil?
             })
             EM.next_tick(&read_and_write)
           }
           EM.next_tick(&read_and_write)

         }
      end
    end
  end
end