# Sudokoup #

Competitive Sudoku backed by EventMachine and HTML5 Websockets

## Try it out ##

Install

	# cd ~/your/projects/
	$ git clone git://github.com/rosskaff/sudokoup.git --recursive

	or

	# download
	$ gem install addressable
	$ gem install em-websocket

Start the server

	$ ./script/server

Run sample clients and forward messages to server via STDIN:

	$ ./script/play NAME

Join the audience to see the game in action:

	$ ruby app.rb
	
	// Go to http://localhost:4567/sudokoup

Server and player scripts accept optional command line parameters

	$ ./script/server [HOST] [PORT] [VIEW_PORT]

	$ ./script/play NAME [HOST] [PORT]

	$ ruby app.rb [-p HOST] [-o PORT]

	HOST:PORT 		 - socket for player clients
	HOST:VIEW_PORT - socket for websocket clients

## Server Protocol ##

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

**REJECT | Reason**

Error when placing number because of provided reason. Play another move.

Reasons:

	VALUE
	ROW
	COLUMN

**WIN**

**LOSE**

## Player Protocol ##

**NAME**

Send name to server following accept.

**ROW COL VAL**

Response to a MOVE message, places value VAL in row ROW, column COL.

Examples:

	// Places value 9 in row 0, column 0 (top left)
	0 0 9

	// Places value 1 in row 8, column 8 (bottom right)
	8 8 1