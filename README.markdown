# Sudokoup #

Competitive Sudoku backed by EventMachine and HTML5 Websockets

## Try it out ##

Start the server

	$ ./script/server

Run sample clients and forward messages to server via STDIN:

	$ ./script/play NAME

Open index.html and press "Connect" to view game

Server and player scripts accept optional command line parameters for

	$ ./script/server HOST PORT VIEW_HOST VIEW_PORT

	$ ./script/play NAME HOST PORT

	HOST:PORT 					- socket for player clients
	VIEW_HOST:VIEW_PORT - socket for websocket clients

## Player Protocol ##

Server Messages

**READY**

Ready message from the server indicates the connection was accepted and player has entered the game.

**WAIT**

Wait message indicates the connection was accepted but the player is in the queue waiting to enter the game.

**START | Player number | Row 0 (top) | Row 1 | Row 2 | ... | Row 8 (bottom)**

Start message indicates game has begun.

Examples:
	
	// Game is starting, you're Player 1
	START | 1 | 0 0 0 1 3 4 0 8 9 | 3 0 0 0 0 5 0 0 0 | ... | 0 2 0 0 1 0 0 6 0

	// Game is starting, you're Player 2
	START | 2 | 0 0 0 1 3 4 0 8 9 | 3 0 0 0 0 5 0 0 0 | ... | 0 2 0 0 1 0 0 6 0

**ADD | Previous move | Row 0 (top) | Row 1 | Row 2 | ... | Row 8 (bottom)**

Add message indicates it is your turn to add a number to the board. The first number set indicates the previous move made by the other player. Move "0 0 0" means no move made previously Current values of board rows follow.

Examples:

	// First move message to Player 1
	MOVE | 0 0 0 | 0 0 0 1 3 4 0 8 9 | 3 0 0 0 0 5 0 0 0 | ... | 0 2 0 0 1 0 0 6 0
	
	// First move message to Player 2, after Player 1 move is '0 0 9'
	MOVE | 0 0 9 | 9 0 0 1 3 4 0 8 9 | 3 0 0 0 0 5 0 0 0 | ... | 0 2 0 0 1 0 0 6 0

**REJECT**

**WIN**

**LOSE**

