module Sudokill

  class Board
    RANGE = (1..9)
    INDICES = (0..8)

    attr_accessor :rows, :error

    def self.from_file(file_name, percent_fill = nil)
      data = File.open(file_name, "r").readlines.join.chomp
      board = new.build_from_string(data)
      if percent_fill
        values      = board.rows.flatten
        zero_count  = values.size - (values.size * percent_fill)
        zero_count.to_i.times do
          row_i = rand(9)
          col_i = rand(9)
          val   = board[row_i][col_i]
          while val.zero?
            row_i = rand(9)
            col_i = rand(9)
            val   = board[row_i][col_i]
          end
          board[row_i][col_i] = 0
        end
      end
      board
    end

    def initialize
      @moves = []
    end

    def build_from_string(string)
      @rows = string.split("\n").map(&:split).map { |row| row.map!(&:to_i) }
      self
    end
    alias_method :build, :build_from_string

    def [](i)
      @rows[i]
    end

    def to_json
      json_rows = @rows.map { |row| "[#{row.join(", ")}]" }.join(", ")
      "[#{json_rows}]"
    end

    def to_msg
      rows.map { |row| row.join(" ") }.join(PIPE)
    end

    def add_move(row, col, val)
      if !valid_space? row, col
        @error = "Out of range error: #{row} #{col} is not a valid space"
        return false
      end
      if !valid_value? val
        @error = "Bad value error: #{val} is not a valid Sudoku value"
        return false
      end
      if !available? row, col, val
        @error = "Space occupied error: #{row} #{col} is occupied"
        return false
      end
      if !required_placement? row, col
        @error = "Required placement error: must play either row #{@moves.last.row} or col #{@moves.last.col}"
        return false
      end
      if row_violation? row, val
        @error = "Constraint violation error: there is already a #{val} in row #{row}!"
        @violated = true
        return false
      end
      if col_violation? col, val
        @error = "Constraint violation error: there is already a #{val} in col #{col}!"
        @violated = true
        return false
      end
      if section_violation? row, col, val
        @error = "Constraint violation error: there is already a #{val} in section #{section(row,col)}!"
        @violated = true
        return false
      end
      @rows[row][col] = val
      @moves << Move.new(row, col, val)
      @error = nil
      true
    end

    def violated?
      @violated
    end

    def available?(row, col, val)
      rows[row][col].zero?
    end

    def valid_space?(row, col)
      rows[row] && rows[row][col]
    end

    def valid_value?(val)
      (1..9).include? val
    end

    def required_placement?(row, col)
      return true if @moves.empty?
      last_move = @moves.last
      return true if full_row?(last_move.row) && full_col?(last_move.col)
      last_move.row == row || last_move.col == col
    end

    def row_violation?(row, val)
      rows[row].any? { |v| v == val }
    end

    def col_violation?(col, val)
      rows.any? { |r| r[col] == val }
    end

    def section_violation?(row, col, val)
      sections = [(0..2), (3..5), (6..8)]
      lrows = sections[(row / 3)].to_a
      lcols = sections[(col / 3)].to_a
      lrows.any? do |r|
        lcols.any? do |c|
          rows[r][c] == val
        end
      end
    end

    def full_row?(row)
      rows[row].sort == RANGE.to_a
    end

    def full_col?(col)
      columns[col].sort == RANGE.to_a
    end

    def section(row, val)
      (row / 3) + (val / 3)
    end

    def columns
      [].tap do |cols|
        INDICES.each do |j|
          col = []
          INDICES.each do |k|
            col << rows[k][j]
          end
          cols << col
        end
      end
    end

  end

  class MultiArray

    def self.new(rows, cols)
      Array.new(rows, Array.new(cols, ""))
    end

  end

end