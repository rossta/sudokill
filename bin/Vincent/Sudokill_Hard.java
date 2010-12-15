import java.io.*;
import java.net.*;
import java.util.*;
import java.util.regex.*;

public class Sudokill_Hard {

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
	static int totalMoves = 0;
	static int initTreeDepth = 4; //for alpha beta pruning

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
				totalMoves++;
	        }
	        else if (fromServer.equals("READY"))
	        	System.out.println("Server is ready");
	        else if (fromServer.equals("WAIT"))
	        	System.out.println("Waiting in queue");
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
		int treeDepth;
		if(totalMoves < 7)
			treeDepth = 2;
		else
			treeDepth = initTreeDepth;
		int index = (int)(Math.random()*temporary.size());
		ArrayList<Move> temp = findValidMoves(state);
		Move bestMove = new Move(0, 0, 0);
		double bestScore = -9999999;
		for(int i = 0; i < temp.size(); i++) {
			Node root = generateTree(state, temp.get(i), treeDepth);
			double tempScore = alphaBeta(root, treeDepth, -99999, 99999);
			System.out.println("Score of (" + root.getMove().toString() + ") is " + tempScore);
			if(tempScore > bestScore) {
				bestScore = tempScore;
				bestMove = new Move(root.getMove().getX(), root.getMove().getY(), root.getMove().getValue());
			}
		}
		return bestMove;
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

	public static Node generateTree(State state, Move m, int d) {
		System.out.println("Generating tree for " + m.toString() + " to depth of " + d);
		Node root = new Node(m, state);
		root.setDepth(0);
		Node parent = root;
		State currentState = state;
		ArrayList<Node> nodes = new ArrayList<Node>(1);
		ArrayList<Node> next = new ArrayList<Node>(1);
		nodes.add(root);
		for(int i = 0; i < d; i++) { //iterates through depths of tree after root which is added above
			if(nodes.isEmpty())
				return root;
			if(nodes.get(0).getDepth() >= d)
				return root;
//			next = generateBranch(currentState, parent);
			int index = 0;
			while(index < nodes.size()) {
				parent = nodes.get(index);
				currentState = parent.getState();
				next.addAll(generateBranch(currentState, parent));
				index++;
			}
			nodes = (ArrayList<Node>)next.clone();
			System.out.println("Checking next depth and size of next is " + nodes.size());
			if(next.isEmpty())
				return root;
		}
		return root;
	}

	public static ArrayList<Node> generateBranch(State state, Node parent) {
//		System.out.println("Generating Branch of depth " + parent.getDepth());
		State currentState = state;
		State deepCopy = updateState(currentState, parent.getMove());
		updateRestrictions(deepCopy, parent.getMove()); //rows, columns and blocks are updated here
		ArrayList<Move> leaves = findValidMoves(deepCopy);
//		Iterator<Move> itr = leaves.iterator();
		int index = 0;
		if(leaves.isEmpty())
			return new ArrayList<Node>(1);
//		while(itr.hasNext()) {
//			Node leaf = new Node(itr.next(), deepCopy);
		while(index < leaves.size()) {
			Node leaf = new Node(leaves.get(index), deepCopy);
			parent.addChild(leaf);
//			System.out.println("Adding child");//
			index++;
		}
//		System.out.println("Returning " + parent.getChildren().size() + " children at depth " + parent.getDepth());
		return parent.getChildren();
	}

	public static State updateState(State state, Move m)
	{
		int[][] tempBoard = new int[9][9];
		int[] tempRows = new int[9];
		int[] tempColumns = new int[9];
		int[] tempBlocks = new int[9];
		for(int i = 0; i < 9; i++) {
			tempRows[i] = state.getRows()[i];
			tempColumns[i] = state.getColumns()[i];
			tempBlocks[i] = state.getBlocks()[i];
			for(int j = 0; j < 9; j++) {
				tempBoard[i][j] = state.getBoard()[i][j];
			}
		}
		int tempLastRow = m.getX();
		int tempLastCol = m.getY();
		tempBoard[m.getX()][m.getY()] = m.getValue();//board and last row/column are the only ones updated here
		State copy = new State(tempBoard, tempRows, tempColumns, tempBlocks, tempLastRow, tempLastCol);
		return copy;
	}

	public static double alphaBeta(Node n, int depth, double a, double b) {
		ArrayList<Node> temp = n.getChildren();
		double alpha, beta;
		if(n.getDepth() == depth || temp.isEmpty()) {
			double tempScore = getScore(n);
			return tempScore;
		}
		alpha = a;
		beta = b;
		if(n.isMin()) {
			for(int i = 0; i < temp.size(); i++) {
				beta = Math.min(beta, alphaBeta(temp.get(i), depth, alpha, beta));
				if(alpha >= beta) {
					return alpha;
				}
			}
			return beta;
		}
		else {
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
		Move tempMove = n.getMove();
		State tempState = updateState(n.getState(), tempMove);
		ArrayList<Move> temp = findValidMoves(tempState);
		if(n.isMin() && temp.isEmpty())
			return -500;
		else if(!n.isMin() && temp.isEmpty())
			return 500;
		else if(n.isMin() && !temp.isEmpty())
			return -1 * temp.size();
		else
			return temp.size();
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

	public Move getMove() {
		return move;
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