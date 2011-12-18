# Sudokill #

Sudokill is competitive Sudoku: it's more than just a one player game. To win Sudokill, you must force your opponent to break the rules of Sudoku.

The game begins with a valid 9x9 Sudoku board with a mix of free and filled spaces. Players take turns placing digits 1-9 in free spaces. A valid move, as in Sudoku, is placing a digit that is not already present in the same row, column or 3x3 section of the board. The additional constraint is that moves must be played in a free space within the same row or column as the previous move played by the opponent. There are exceptions: for the first move of the game and when both the row and column of the previous move have no available spaces, the move may be played in any free space on the board.

This is an implementation of the game devised by Dennis Shasha for his Heuristics class at New York University. [Original game rules](http://www.cs.nyu.edu/courses/fall10/G22.2965-001/sudokill.html)


## Try it out ##

You can play the game in browsers enabled with Websockets or Flash. Visit [Sudokill](http://rossta.github.com/sudokill) and enter your name to connect. Since all games are open to the public, you'll be able to see other players connected as well.

About the controls: "Switch game" will take you to another game room. Press "Join game" to get in line to play the game. You can select a computer player to play against using the "Choose opponent" menu. Press "Play" to start a game when two players are in the "Now playing" list. You can alter how many numbers fill the board at the start with the density controls.

Instructions for connecting your own computer client to play the game through a socket connection and the server protocol are described below.


### Implementation ###

The game server is backed by EventMachine. Sinatra serves up the HTML, CSS and Javascript assets for rendering the view in browser. Pressing connect


### Running the game locally ###

Clone the repo

	$ git clone git://github.com/rossta/sudokill.git

Install dependencies via bundler. [Ruby newbies should check out the wiki]([[Setup-for-Ruby-Newbies]]) for more details

	$ bundle

Start the server

	$ ./bin/sudokill

Visit http://localhost:4567, enter a visitor name, and "Connect".

For best performance, use a browser that supports HTML5 websockets

	* Chrome 5+
	* Safari 5+
	* Firefox 4 beta
	* Opera 10.70

Choose a player bot to compete with or open a second page to the same url to play against yourself.

Press "Play" when two players are connected to get a game going.

You can also play against a friend (or yourself in two browser windows) at [http://www.sudokill.com](http://rossta.github.com/sudokill)

To learn the TCP protocol or for an extra challenge, play at sudokill.com via command line:

	$ ./bin/sudokill play NAME

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
