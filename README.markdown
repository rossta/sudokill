# Sudokoup #

Competitive Sudoku backed by EventMachine and HTML5 Websockets

## Try it out ##

	Start the server

		$ ./script/server

	Run sample clients and forward messages to server via STDIN:

  	$ ./script/play NAME

	Open index.html and press "Connect" to view game


## Configure ##

	Server and player scripts accept optional command line parameters for

		$ ./script/server HOST PORT VIEW_HOST VIEW_PORT
		$ ./script/play NAME HOST PORT

		HOST:PORT 					- socket for player clients
		VIEW_HOST:VIEW_PORT - socket for websocket clients

