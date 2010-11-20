module Sudokoup
  class Move
    attr_reader :row, :col, :val
    def initialize(row, col, val)
      @row = row
      @col = col
      @val = val
    end

    def to_json
      "[#{to_coord.join(", ")}]"
    end

    def to_coord
      [row, col, val]
    end
  end
end