Sudokill Websocket JSON Protocol

Accepts commands in JSON format

Commands

UPDATE
  - Changes the value of a single game square
  Required:
  - action          : string "UPDATE"
  - x coordinate    : integer i, 0 <= i <= 8
  - y coordinate    : integer j, 0 <= j <= 8
  - value to insert : integer k, 1 <= k <= 9
  Examples:
    {"action":"UPDATE","x":1,"y":1,"value":7}
    {"action":"UPDATE","x":8,"y":7,"value":3}
