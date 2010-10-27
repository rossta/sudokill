Sudokl
======

Sudoku backed by EventMachine based, asynchronous WebSocket server.

Start server

  ./script/server

Testing the game board

	Start server proxy for testing

	  ./script/echo

	Start websocket client

	  ./script/view

	Open index.html

	Use STDIN on echo server to send data to the websocket client. Example:
		
		{"action":"UPDATE","x":1,"y":1,"value":7}
		