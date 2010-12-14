import java.io.*;
import java.net.*;
import java.util.*;
import java.util.regex.*;

public class Sudokill_Easy {

	static int[][] currentBoard = new int[9][9];
	static int[] curRows = new int[9];
	static int[] curCols = new int[9];
	static int[] curBlocks = new int[9];
	static State curState;
	static int playerNumber;
	static int totalPlayers;
	static int lastRow = -1;
	static int lastColumn = -1;
	static int lastValue = -1;

	public static void main(String[] args) throws Exception {
		Socket socket = null;
	    PrintWriter out = null;
	    BufferedReader in = null;
	    String host = args[0];
		String portString = args[1];
		String name = args[2];
		int port = Integer.parseInt(portString);
	    try {
	        socket = new Socket(host, port);
	        out = new PrintWriter(socket.getOutputStream(), true);
	        in = new BufferedReader(new InputStreamReader(socket.getInputStream()));
	    }
	    catch (UnknownHostException e) {
	        System.err.println("Don't know about host: localhost.");
	        System.exit(1);
	    }
	    catch (IOException e) {
	        System.err.println("Couldn't get I/O for the connection to: localhost.");
	        System.exit(1);
	    }

	    BufferedReader stdIn = new BufferedReader(new InputStreamReader(System.in));
	    String fromServer;
	    String fromUser;

		out.println(name);
	    while ((fromServer = in.readLine()) != null) {
	        System.out.println("Server: " + fromServer);
	        if (fromServer.equals("WIN") || fromServer.equals("LOSE") || fromServer.startsWith("GAME OVER"))
	            break;
	        if (fromServer.startsWith("START"))
				initBoard(fromServer);
	        else if (fromServer.startsWith("ADD")) {
				Move temp = updateBoard(fromServer);
				out.println(temp.toString());
	        }
	        else if (fromServer.equals("READY"))
	        	System.out.println("Server is ready");
	        else
	        	updateLastMove(fromServer);
	    }
	    out.close();
	    in.close();
	    stdIn.close();
	    socket.close();
	}

	public static void initBoard(String str) {
		System.out.println("Initializing board");
		ArrayList<Integer> inputString = new ArrayList<Integer>(1);
		Pattern p = Pattern.compile("-?\\d+");
		Matcher m = p.matcher(str);
		while(m.find()) {
			inputString.add(Integer.parseInt(m.group()));
		}
		playerNumber = inputString.get(0);
		totalPlayers = inputString.get(1);
		System.out.println("Player Number:	" + playerNumber);
		System.out.println("Total Players:	" + totalPlayers);
		int temp;
		for(int i = 0; i < 81; i++) {
			temp = i + 2;
			currentBoard[i/9][i%9] = (int)inputString.get(temp);
		}
	}

	//Same as initBoard except without the first 2 integers that designate player number and total players
	public static Move updateBoard(String str) {
		System.out.println("Updating board");
		ArrayList<Integer> inputString = new ArrayList<Integer>(1);
		Pattern p = Pattern.compile("-?\\d+");
		Matcher m = p.matcher(str);
		if(lastRow == -1 && lastColumn == -1 && lastValue == -1 && playerNumber == 1) {
			lastRow = (int)(Math.random()*9);
			lastColumn = (int)(Math.random()*9);
			lastValue = 0;
		}
		curState = new State(currentBoard, curRows, curCols, curBlocks, lastRow, lastColumn);
		while(m.find()) {
			inputString.add(Integer.parseInt(m.group()));
		}
		for(int i = 0; i < 81; i++) { //i is the # of the value
			int temp = (int)inputString.get(i);
			currentBoard[i/9][i%9] = temp;
			curState.updateBoard(currentBoard);
			if(temp > 0) {
				Move tempMove = new Move(i/9, i%9, temp);
				updateRestrictions(curState, tempMove);
			}
		}
		Move tempMove = findMove(curState);
		return tempMove;
	}

	public static void updateLastMove(String str) {
		System.out.println("Updating last move");
		ArrayList<Integer> inputString = new ArrayList<Integer>(1);
		Pattern p = Pattern.compile("-?\\d+");
		Matcher m = p.matcher(str);
		while(m.find()) {
			inputString.add(Integer.parseInt(m.group()));
		}
		System.out.println("Updating last move info");
		lastRow = inputString.get(0);
		lastColumn = inputString.get(1);
		lastValue = inputString.get(2);
		if(lastRow == -1 && lastColumn == -1 && lastValue == -1 && playerNumber == 1) {
			lastRow = (int)(Math.random()*9);
			lastColumn = (int)(Math.random()*9);
			lastValue = 0;
		}
	}

	public static void updateRestrictions(int[] rows, int[] columns, int[] blocks, Move m) {
//		System.out.println("Updating Restrictions with arrays");
		int row = m.getX(); // #/9
		int col = m.getY(); // #%9
		int block = ((col/3) + (row/3)*3); // #%9/3 + (#/9/3)*3
		int value = m.getValue();
		rows[row] |= (1<<value);
		columns[col] |= (1<<value);
		blocks[block] |= (1<<value);
	}

	public static void updateRestrictions(State state, Move m) {
//		System.out.println("Updating Restrictions with state");
		int row = m.getX(); // #/9
		int col = m.getY(); // #%9
		int block = ((col/3) + (row/3)*3); // #%9/3 + (#/9/3)*3
		int value = m.getValue();
		state.getRows()[row] |= (1<<value);
		state.getColumns()[col] |= (1<<value);
		state.getBlocks()[block] |= (1<<value);
//		System.out.println("Restrictions updated: " + state.getRows()[row] + "," + state.getColumns()[col] + "," + state.getBlocks()[block]);
	}

	public static Move findMove(State state) {
		ArrayList<Move> temporary = findValidMoves(state);
		int index = (int)(Math.random()*temporary.size());
		Move temp = temporary.get(index);
		System.out.println(temporary.size());
		return temp;
	}

	public static ArrayList<Move> findValidMoves(State state) {
		ArrayList<Move> possibleMoves = new ArrayList<Move>(1);
		int column = state.getLastColumn();
		int row = state.getLastRow();
		for(int i = 0; i < 9; i++) { //checks the columns of the row
			if(state.getBoard()[row][i] == 0) {
				for(int j = 1; j < 10; j++) {//checks the 1-9 values
					if((state.getBoard()[row][i] == 0 && (state.getRows()[row] & (1<<j)) == 0 && (state.getColumns()[i] & (1<<j)) == 0 && (state.getBlocks()[((i/3) + (row/3)*3)] & (1<<j)) == 0)) {
						Move temp = new Move(row, i, j);
						possibleMoves.add(temp);
					}
				}
			}
		}
		for(int i = 0; i < 9; i++) {
			if(state.getBoard()[i][column] == 0) {
				for(int j = 1; j < 10; j++) {
					if((state.getBoard()[i][column] == 0 && (state.getRows()[i] & (1<<j)) == 0 && (state.getColumns()[column] & (1<<j)) == 0 && (state.getBlocks()[((column/3) + (i/3)*3)] & (1<<j)) == 0)) {
						Move temp = new Move(i, column, j);
						possibleMoves.add(temp);
					}
				}
			}
		}
		return possibleMoves;
	}

	public static double alphaBeta(Node n, int depth, double a, double b) {
		double alpha, beta;
		if(n.getDepth() == depth) {
			double tempScore = getScore(n);
			if(n.isMin()){
				return -1 * tempScore;
			}
			return tempScore;
		}
		alpha = a;
		beta = b;
		if(n.isMin()) {
			ArrayList<Node> temp = n.getChildren();
			for(int i = 0; i < temp.size(); i++) {
				beta = Math.min(beta, alphaBeta(temp.get(i), depth, alpha, beta));
				if(alpha >= beta) {
					return alpha;
				}
			}
			return beta;
		}
		else {
			ArrayList<Node> temp = n.getChildren();
			for(int i = 0; i < temp.size(); i++) {
				alpha = Math.max(alpha, alphaBeta(temp.get(i), depth, alpha, beta));
				if(alpha >= beta) {
					return beta;
				}
			}
			return alpha;
		}
	}

	public static double getScore(Node n) {
		ArrayList<Move> temp = findValidMoves(n.getState());
		if(temp.isEmpty())
			return 1;
		return 0;
	}
}

class Move {

	private int xloc; //row between 0 and 8
	private int yloc; //column between 0 and 8
	private int value; //value between 1 and 9

	public Move(int x, int y, int v) {
		xloc = x;
		yloc = y;
		value = v;
	}

	public int getX() {
		return xloc;
	}

	public int getY() {
		return yloc;
	}

	public int getValue() {
		return value;
	}

	public String toString() {
		return "" + xloc + " " + yloc + " " + value;
	}
}

class Node {

	private Node parent;
	private ArrayList<Node> children = new ArrayList<Node>(1);
	private int depth;
	private boolean traveresed;
	private Move move;
	private State state;

	public Node(Move move, State state) {
		traveresed = false;
		this.move = move;
		this.state = state;
	}
	//data stored on node consists of the row/column and the value to be added

	public void addChild(Node child) {
		children.add(child);
		child.setParent(this);
	}
	//when adding a child, set the parent as well, which updates the child's depth

	public void setParent(Node parent) {
		this.parent = parent;
//		parent.addChild(this);
		depth = parent.getDepth() + 1;
	}

	public void traverese() {
		traveresed = true;
	}

	public boolean isTraveresed() {
		return traveresed;
	}

	public ArrayList<Node> getChildren() {
		return children;
	}

	public int getNumberOfChildren() {
		if(children.isEmpty())
			return 0;
		else
			return children.size();
	}

	public Node getParent() {
		return parent;
	}

	public int getDepth() {
		return depth;
	}

	public void setDepth(int x) {
		depth = x;
	}

	public State getState() {
		return state;
	}

	public boolean isMin() {
	//determine whether node is minimal or maximum node
		if(depth%2 == 0)
			return false;
		else
			return true;
	}

	public String toString() {
		return move.toString();
	}
}

class State {

	private int[][] board = new int[9][9];
	private int[] rows = new int[9];
	private int[] columns = new int[9];
	private int[] blocks = new int[9];
	private int lastRow;
	private int lastColumn;

	public State(int[][] board, int[] rows, int[] columns, int[] blocks, int x, int y) {
		for(int i = 0; i < 9; i++) {
			this.rows[i] = rows[i];
			this.columns[i] = columns[i];
			this.blocks[i] = blocks[i];
			for(int j = 0; j < 9; j++) {
				this.board[i][j] = board[i][j];
			}
		}
		lastRow = x;
		lastColumn = y;
	}

	public void updateBoard(int[][] x) {
		board = x;
	}

	public int[][] getBoard() {
		return board;
	}

	public int[] getRows() {
		return rows;
	}

	public int[] getColumns() {
		return columns;
	}

	public int[] getBlocks() {
		return blocks;
	}

	public int getLastRow() {
		return lastRow;
	}

	public int getLastColumn() {
		return lastColumn;
	}
}