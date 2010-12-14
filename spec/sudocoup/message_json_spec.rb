require 'spec_helper'

describe Sudocoup::MessageJSON do
  describe "move_json" do
    it "should return action, move, and status as json object" do
      json_s = Sudocoup::MoveJSON.to_json(mock(Sudocoup::Move, :to_json => "[1, 2, 3]"), :ok)
      json = JSON.parse(json_s)
      json["action"].should == "UPDATE"
      json["value"].should == [1,2,3]
      json["status"].should == "ok"
    end
  end
  describe "board_json" do
    it "should return action, move, and status as json object" do
      board = mock(Sudocoup::Board, :to_json => "[[1,2,3],[4,5,6],[7,8,9]]", :build => nil)
      json_s = Sudocoup::BoardJSON.to_json(board)
      json = JSON.parse(json_s)
      json["action"].should == "CREATE"
      json["values"].should == [[1,2,3],[4,5,6],[7,8,9]]
    end
  end
  describe "status_json" do
    it "should return action and given message as json" do
      json_s = Sudocoup::StatusJSON.to_json(:ready, "Game is starting!");
      json = JSON.parse(json_s)
      json["action"].should == "STATUS"
      json["message"].should == "Game is starting!"
      json["state"].should == "ready"
    end
  end
  describe "player_json" do
    before(:each) do
      @player_1 = mock_player(:number => 1, :current_time => 14, :name => "Player 1", :to_json => %Q|{"number":1}|)
      @player_2 = mock_player(:number => 2, :current_time => 25, :name => "Player 2", :to_json => %Q|{"number":2}|)
    end
    it "should return TIME message with player ids and times" do
      max_time = 120
# {
#   players: [
#     {
#       number: 1,
#       time: {
#         current: 14,
#         max: 120
#       },
#       name: 'Player 1',
#       moves: 3
#     },
#     {
#       number: 2,
#       time: {
#         current: 25,
#         max: 120
#       },
#       name: 'Player 2',
#       moves: 2
#     }
#   ]
# }
      json_s = Sudocoup::PlayerJSON.to_json([@player_1, @player_2], max_time)
      json = JSON.parse(json_s)
      json['action'].should == 'SCORE'
      players = json['players']
      players.size.should == 2
      player_1_json = players.shift
      player_1_json['number'].should == 1
    end
    it "should omit max time if nil" do
      json_s = Sudocoup::PlayerJSON.to_json([@player_1, @player_2])
      json = JSON.parse(json_s)
      json['action'].should == 'SCORE'
    end
  end
  describe "queue_json" do
    it "should return TIME message with player ids and times" do
      player_1 = mock_player(:number => nil, :current_time => 0, :name => "Player 1", :to_json => %Q|{"name":"Player 1"}|)
      player_2 = mock_player(:number => nil, :current_time => 0, :name => "Player 2", :to_json => %Q|{"name":"Player 2"}|)
# {
#   players: [
#     {
#       name: 'Player 1'
#     },
#     {
#       name: 'Player 2'
#     }
#   ]
# }
      json_s = Sudocoup::QueueJSON.to_json([player_1, player_2])
      json = JSON.parse(json_s)
      json['action'].should == 'QUEUE'
      players = json['players']
      players.size.should == 2
      player_1_json = players.shift
      player_2_json = players.shift
      player_1_json['name'].should == "Player 1"
      player_2_json['name'].should == "Player 2"
    end
  end
end
