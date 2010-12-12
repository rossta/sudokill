module Sudocoup
  module Player
    class Naive < EventMachine::Connection
      include EM::Deferrable

      attr_accessor :last_move, :move

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
          log line
          case line.to_s.chomp
          when /^READY/
            puts "getting ready"
          when /^WAIT/
            puts "waiting"
          when /^START/
            puts "game started!"
          when /^ADD/
            find_rows(line)

            values  = (1..9).to_a
            val     = nil
            if !last_move.nil?
              row_i   = last_move[0]
              col_i   = last_move[1]
            else
              row_i   = 0
              col_i   = 0
            end
            
            row_vals  = row(row_i)
            (0..8).each do |j|
              break if !row_vals.any? { |v| v.zero? }
              next if j == col_i
              row_val   = row_vals[j]
              next unless row_val.zero?
              col_vals  = column(j)
              sec_vals  = section(row_i, j)
              val = (1..9).to_a.detect { |v|
                !row_vals.include?(v) && !col_vals.include?(v) && !sec_vals.include?(v)
              }
              next unless !val.nil?
              col_i = j
              break
            end
            
            col_vals  = column(col_i)
            if val.nil?
              (0..8).each do |k|
                break if !col_vals.any? { |v| v.zero? }
                next if k == row_i
                row_val   = col_vals[k]
                next unless row_val.zero?
                row_vals  = row(k)
                sec_vals  = section(k, col_i)
                val = (1..9).to_a.detect { |v|
                  !row_vals.include?(v) && !col_vals.include?(v) && !sec_vals.include?(v)
                }
                next unless !val.nil?
                row_i = k
                break
              end
            end

            if val.nil? # guess
              row_i = rand(9)
              col_i = rand(9)
              val   = rand(9) + 1
            end

            @move = "#{row_i} #{col_i} #{val}"
            log "playing #{@move}"
            send @move
          when /^\d+ \d+ \d+/
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

      def row(row_i)
        @rows && @rows[row_i]
      end

      def column(col_i)
        @rows && @rows.map { |r| r[col_i] }
      end

      def section(row_i, col_i)
        [].tap do |sect|
            j = (row_i / 3)
            k = (col_i / 3)
          (0..2).each do |l|
            (0..2).each do |m|
              sect << @rows[(j * 3) + l][(k * 3) + m]
            end
          end
        end
      end

      def find_rows(command)
        response = command.split("|")
        cmd = response.shift
        @rows = response.map { |row| row.split.map(&:to_i) }
        @rows
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