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

1. READY
Ready message from the server indicates the connection was accepted and player has entered the game.

2. WAIT
Wait message indicates the connection was accepted but the player is in the queue waiting to enter the game.

3. START | <Player number> | <Row 1 (top)> | <Row 2> | <Row 3> | ... | <Row 9 (bottom)>
Start message indicates game has begun. Format of message is:  your player role | row 1 | row 2 | row 3 | ... | row 9

Examples:
Player 1
	START | 1 | 0 0 0 1 3 4 0 8 9 | 3 0 0 0 0 5 0 0 0 | ... | 0 2 0 0 1 0 0 6 0

Player 2
	START | 2 | 0 0 0 1 3 4 0 8 9 | 3 0 0 0 0 5 0 0 0 | ... | 0 2 0 0 1 0 0 6 0

4. ADD | <Previous move> | <Row 1 (top)> | <Row 2> | <Row 3> | ... | <Row 9 (bottom)>
Add message indicates it is your turn to add a number to the board. The first number set indicates the previous move made by the other player. Current values of board rows follow.

Examples:
First move to player one
	MOVE | 0 0 0 | 0 0 0 1 3 4 0 8 9 | 3 0 0 0 0 5 0 0 0 | ... | 0 2 0 0 1 0 0 6 0

Second move to player two, after player one moves "1 1 9"
	MOVE | 1 1 9 | 9 0 0 1 3 4 0 8 9 | 3 0 0 0 0 5 0 0 0 | ... | 0 2 0 0 1 0 0 6 0
