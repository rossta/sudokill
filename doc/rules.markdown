#Sudokill#

Dennis Shasha

Omniheurist Course

Computer Science

##Description##

Here we consider a competitive version of Sudoku. (For a summary of the rules and the strategy to program Sudoku see sudoku . You are given the standard Sudoku board. There is an initial layout of numbers that violates no constraints. Players alternate in placing numbers on the board, always trying to avoid violating the constraints. The first player may begin by playing in any unoccupied space. After this each player must play in an unoccupied space in either the same row or the same column as the previous player's last move (unless there are no such squares at all in which case that player may play anywhere). The first player to make a move that violates the Sudoku rules loses.

The first player who violates the constraints loses.

The 2008 winner Aravindan Dharmalingam used a minimax algorithm up to a certain depth. To solve the frontier problem he ascribed a value of -1 to a node that would make him lose, 1 to a node that would make him win, and 0 otherwise.

##Architecture##

Your job is to draw the original Sudoku board, place some numbers that do not violate the Sudoku constraints, then accept moves from each player and place them on the board. If any move violates a Sudoku constraint, then you should detect that and declare the other player to be the winner. This should work for human players as well as computer players. You should also record the time elapsed for each player.