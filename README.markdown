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

Sudokill will run on Ruby versions 1.8.7 and 1.9.x. [Ruby newbies should check out the wiki]([[Setup-for-Ruby-Newbies]]) for more details. 

Install dependencies via bundler. 
	
	$ gem install bundler
	$ bundle

Start the server. Visit http://localhost:4567, enter a visitor name, and "Connect".

	$ ./bin/sudokill
	$ open http://localhost:4567 

Choose a player bot to compete with or open a second page to the same url to play against yourself. Press "Play" when two players are connected to get a game going.

For best performance, use a browser that supports HTML5 websockets

* Chrome 5+
* Safari 5+
* Firefox 4 beta
* Opera 10.70

To learn the TCP protocol (or for an extra challenge), you can enter the game on sudokill.com via command line:

	$ ./bin/sudokill play NAME
