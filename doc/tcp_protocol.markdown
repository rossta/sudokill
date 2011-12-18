## Writing a TCP Player ##

Bot players can be written in any language that can communicate over TCP. Player bots should
be able to connect to the Sudokill server (default port 4444 when run locally) and respond
to messages according to the following server protocol.


## Server Protocol ##

**READY**

Connection to server was accepted, player has entered the game


**WAIT**

Connection was accepted, but player is in the queue waiting to enter the game


**START**

Game has begun; Board rows listed in order: row 0 (top), row 1, row 2, ..., row 8 (bottom)

Examples:

	START|1|2|0 0 0 1 3 4 0 8 9|3 0 0 0 0 5 0 0 0| ... |0 2 0 0 1 0 0 6 0
	// Game is starting, you're Player 1 of 2 players, then board rows 0 - 8

	START|2|2|0 0 0 1 3 4 0 8 9|3 0 0 0 0 5 0 0 0| ... |0 2 0 0 1 0 0 6 0
	// Game is starting, you're Player 2 of 2 players, then board rows 0 - 8


**ROW COL VAL PLAYER-ID**

A successful move was made

Example:

	0 1 8 2
	// indicates player 2 added the value 8 at row 0, col 1


**ADD**

It's your turn

Example:

	ADD|0 0 0 1 3 4 0 8 9|3 0 0 0 0 5 0 0 0| ... |0 2 0 0 1 0 0 6 0
	//Your move and current board rows 0 - 8


**REJECT**

Your move was not accepted. Reasons:

	1 Not in the game
	2 Wait your turn

Example:

	REJECT|1 Not in the game
	//Rejection! You're on the bench


**GAME OVER**

A player violated the constraints or left the game. Winner and reason is noted. Both players are disconnected.

	GAME OVER|Rossta WINS! BadGuy played 4 7 5: Space occupied error, 4 7 is occupied


## Player Protocol ##


**NAME**

Send your name immediately on connect


**ROW COL VAL**

Send your move after receiving ADD

Examples:

	0 0 9
	// Places value 9 in row 0, column 0 (top left)

	8 8 1
	// Places value 1 in row 8, column 8 (bottom right)
