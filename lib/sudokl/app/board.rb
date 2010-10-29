module Sudokl
  module App

    class Board
      CONFIG_1 = <<-TXT
7 0 5 0 0 0 2 9 4
0 0 1 2 0 6 0 0 0
0 0 0 0 0 0 0 0 7
9 0 4 5 0 0 0 2 0
0 0 7 3 6 2 1 0 0
0 2 0 0 0 1 7 0 8
1 0 0 0 9 0 0 0 0
0 0 0 7 0 5 9 0 0
5 3 9 0 0 0 8 0 2
      TXT

      CONFIG_2 = <<-TXT
8 0 0 0 0 4 0 0 1
0 0 0 0 0 0 0 0 0
0 3 2 0 5 0 4 9 0
0 0 5 0 0 8 3 0 0
3 0 0 6 1 9 0 0 5
0 0 1 3 0 0 6 0 0
0 8 4 0 7 0 1 2 0
0 0 0 0 0 0 0 0 0
7 0 0 2 0 0 0 0 4
      TXT

      attr_reader :config

      def build_from_string(string = CONFIG_1)
        @config = string.split("\n").map(&:split).map { |row| row.map!(&:to_i) }
        @config
      end
      alias_method :build, :build_from_string

      def [](i)
        @config[i]
      end

      def to_json
        rows = @config.map { |row| "[#{row.join(", ")}]" }.join(", ")
        "[#{rows}]"
      end

    end

    class MultiArray

      def self.new(rows, cols)
        Array.new(rows, Array.new(cols, ""))
      end

    end
  end
end