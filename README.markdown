# Sudocoup #

Competitive Sudoku backed by EventMachine and HTML5 Websockets

## Try it out ##

### Mac / Linux ###

Install

	$ git clone git://github.com/rosskaff/sudocoup.git

	// or get sudocoup source using "Download" project link


### Windows ###

Install Ruby 1.8.7 from [RubyInstaller](http://rubyinstaller.org): useful [installation info](http://ruby.about.com/od/beginningruby/ss/Installing-A-Ruby-Development-Environment-On-Windows.htm)

		$ gem install eventmachine --platform=mswin32
		$ gem install em-websocket
		$ gem install sinatra
		$ gem install thin --platform=mswin32 // optional: alternative web server to WEBrick

Dependencies

	$ gem install eventmachine
	$ gem install em-websocket
	$ gem install sinatra
	$ gem install thin // optional: alternative web server to WEBrick

Start the server

	$ ruby script/server

Join the audience to see the game in action:

	$ ruby script/web

	// Visit http://localhost:45678/

Run sample clients and forward messages to server via STDIN:

	$ ruby script/play NAME

Server and player scripts accept optional command line parameters

	$ ruby script/server [HOST] [PORT] [WEBSOCKET_PORT]

	$ ruby script/web [HOST] [PORT]

	$ ruby script/play NAME [HOST] [PORT]


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


**REJECT|REASON**

Your move was not accepted.

Reasons:

	VALUE
	ROW
	COLUMN


**WIN**


**LOSE**


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
