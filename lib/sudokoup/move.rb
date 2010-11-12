module Sudokoup
  class Move
    attr_reader :x, :y, :value
    def initialize(x, y, value)
      @x = x
      @y = y
      @value = value
    end

    def to_json
      "[#{to_coord.join(", ")}]"
    end

    def to_coord
      [x, y, value]
    end
  end
end