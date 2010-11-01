require 'spec_helper'

describe Sudokl::App::Board do

  describe "build_from_string" do

    it "should load CONFIG_1 config" do
      board = Sudokl::App::Board.new
      board.build_from_string(Sudokl::CONFIG_1)
      values = Sudokl::CONFIG_1.split("\n").map(&:split)
      values.each_with_index do |row, i|
        row.each_with_index do |value, j|
          board[i][j].should == value.to_i
        end
      end
    end
  end

  describe "to_json" do
    before(:each) do
      @board = Sudokl::App::Board.new
      @board.build_from_string(Sudokl::CONFIG_1)
    end
    it "should return stringified json version of board" do
      json = <<-JSON
[[7, 0, 5, 0, 0, 0, 2, 9, 4], [0, 0, 1, 2, 0, 6, 0, 0, 0], [0, 0, 0, 0, 0, 0, 0, 0, 7], [9, 0, 4, 5, 0, 0, 0, 2, 0], [0, 0, 7, 3, 6, 2, 1, 0, 0], [0, 2, 0, 0, 0, 1, 7, 0, 8], [1, 0, 0, 0, 9, 0, 0, 0, 0], [0, 0, 0, 7, 0, 5, 9, 0, 0], [5, 3, 9, 0, 0, 0, 8, 0, 2]]
JSON
      @board.to_json.should == json.chomp
    end
  end
end
