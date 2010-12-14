module Sudocoup
  class Move
    attr_reader :row, :col, :val, :num

    def self.build(move_s, num)
      new(*(move_s.split + [num]).map(&:to_i))
    end

    def initialize(row, col, val, num = nil)
      @row = row
      @col = col
      @val = val
      @num = num
    end

    def to_json
      "[#{to_coord.join(", ")}]"
    end

    def to_coord
      [row, col, val, num].compact
    end
  end
end