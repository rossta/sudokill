module Sudokl
  module App

    class Board

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