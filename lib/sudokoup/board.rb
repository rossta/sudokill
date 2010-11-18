module Sudokoup

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

    def to_msg
      @config.map { |row| row.join(" ") }.join(" | ")
    end

    def add_move(x, y, value)
      return false unless available? x, y, value
      
      @config[x][y] = value

      true
    end

    def violated?
      false
    end

    def available?(x, y, value)
      return false unless @config[x] && @config[x][y]
      return false unless (1..9).include? value
      return false unless @config[x][y].zero?
      true
    end

  end

  class MultiArray

    def self.new(rows, cols)
      Array.new(rows, Array.new(cols, ""))
    end

  end

end