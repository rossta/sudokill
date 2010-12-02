# Sudocoup #

Competitive Sudoku backed by EventMachine and HTML5 Websockets

## Try it out ##

Install

	# cd ~/your/projects/
	$ git clone git://github.com/rosskaff/sudocoup.git --recursive

	or

	# Get source using "Download" project link, then
	$ gem install addressable
	$ gem install em-websocket

Start the server

	$ ./script/server

Run sample clients and forward messages to server via STDIN:

	$ ./script/play NAME

Join the audience to see the game in action:

	$ ruby app.rb

	// Go to http://localhost:45678/

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

**START**

Start message indicates game has begun: START, your player number, player total, row 0 (top), row 1, row 2, ..., row 8 (bottom)

Examples:

	START|1|2|0 0 0 1 3 4 0 8 9|3 0 0 0 0 5 0 0 0| ... |0 2 0 0 1 0 0 6 0
	// Game is starting, you're Player 1 of 2 players, then board rows 0 - 8

	START|2|2
	// Game is starting, you're Player 2 of 2 players, then board rows 0 - 8

**<ROW> <COL> <VAL> <PLAYER ID>**
The server will broadcast each successful move to all players in the form ROW COL VAL PLAYER_ID.

Example:

	0 1 8 2
	// indicates player 2 added the value 8 at row 0, col 1

**ADD**

Add message indicates it is your turn: ADD, row 0 (top), row 1, row 2, ..., row 8 (bottom).

Example:

	ADD|0 0 0 1 3 4 0 8 9|3 0 0 0 0 5 0 0 0| ... |0 2 0 0 1 0 0 6 0
	//Your move and current board rows 0 - 8
	
**REJECT**

Error when placing number because of provided reason. Play another move.

Reasons:

	VALUE
	ROW
	COLUMN

**WIN**

**LOSE**

## Player Protocol ##

**NAME**

Send name to server immediately when connecting.

**<ROW> <COL> <VAL>**

Respond to an ADD message from the server with value VAL in row ROW, column COL.

Examples:

	0 0 9
	// Places value 9 in row 0, column 0 (top left)

	8 8 1
	// Places value 1 in row 8, column 8 (bottom right)
	