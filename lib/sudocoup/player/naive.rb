module Sudocoup
  module Player
    class Naive < EventMachine::Connection
      include EM::Deferrable

      attr_accessor :last_move

      def initialize(options = {})
        @name = options[:name]
        @stop = options[:stop]
        @data = ''
      end

      def post_init
        send @name
      end

      def receive_data(data)
        return if data.nil?
        @data << data
        while line = @data.slice!(/(.+)\r?\n/)
          log "Server >> #{line}"
          case line.to_s.chomp
          when /^READY/
            puts "getting ready"
          when /^WAIT/
            puts "waiting"
          when /^START/
            puts "game started!"
          when /^ADD/
            move = "0 4 8"
            response = line.split("|")
            cmd = response.shift
            rows = response.map { |row| row.split.map(&:to_i) }

            values  = (1..9).to_a

            val     = nil
            if !last_move.nil?
              row_i   = last_move[0]
              col_i   = last_move[1]
            else
              row_i   = 0
              col_i   = 0
            end

            (0..8).each do |j|
              row = rows[row_i]
              col = (0..8).to_a.map { |k| rows[k][j] }
              sec = [].tap do |s|
                sec_i = row_i / 3
                sec_j = j / 3
                (0..2).each do |m|
                  (0..2).each do |n|
                    s << rows[sec_i + n][sec_j + m]
                  end
                end
              end
              row_val = row[j]
              next unless row_val.zero?
              val = (1..9).to_a.detect { |v| !row.include?(v) && !col.include?(v) && !sec.include?(v) }
              next unless !val.nil?
              col_i = j
              break
            end
            if val.nil?
              col_i = rand(9) 
              val   = rand(9) + 1
            end
            move = "#{row_i} #{col_i} #{val}"
            log "playing #{move}"
            send move
          when /^\d+ \d+ \d+ \d+$/
            @last_move = line.chomp.split.map(&:to_i)
            log "last move #{@last_move.join(' ')}"
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

           client = EM.connect host, port, Naive, :name => name, :stop => stop
         }
      end

    end
  end
end