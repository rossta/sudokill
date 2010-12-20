/*
*
*	Class SudokillPlayer.java
*	Created by Rachit Parikh
*	Heuristic Problem Solving - Fall 2010
*
*/

import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.InputStreamReader;
import java.io.OutputStreamWriter;
import java.net.Socket;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Random;

public class SudokillPlayer {

	public final int MAX_ROWS = 9;
	public final int MAX_COLS = 9;
	
	int numplayers, thisplayer;
	int [][] gameboard = new int[MAX_ROWS][MAX_COLS];
	int curr_row = -1, curr_col = -1;
	
	HashMap<String, ArrayList<String>> squares = new HashMap<String, ArrayList<String>>();
	
	static Random r = new Random(System.currentTimeMillis());

	
	public SudokillPlayer(String host, int port, String name) {
		try {
			System.out.println( "connecting" );
			Socket s = new Socket( host, port );
			BufferedWriter bw = new BufferedWriter(new OutputStreamWriter(s.getOutputStream() ) );
			BufferedReader br = new BufferedReader(new InputStreamReader(s.getInputStream() ) );
			
			System.out.println("Sending name to Server: " + name);
			bw.write( name + "\n" );
			bw.flush();
			
			String in = "";
			
			generateSquares();
			
			while ((in = br.readLine()) != null) {
				System.out.println(in);
				
				String fromServer = in.toUpperCase();
				
				if (fromServer.startsWith("READY")) {
					System.out.println("Connection accepted by Server. Ready to Play.");
				} else if (fromServer.startsWith("WAIT")) {
					System.out.println("Connection accepted by Server. Waiting futher instructions.");
				} else if (fromServer.startsWith("START")) {
					System.out.println("Starting game...");
					String[] toks = fromServer.split("\\|");
					thisplayer=Integer.parseInt(toks[1]);
					numplayers=Integer.parseInt(toks[2]);
					String moves = fromServer.replaceAll("START\\|[\\d]+\\|[\\d]+\\|", "");
					setBoardState(moves);
					printBoardState(gameboard);
				} else if (fromServer.startsWith("ADD")) {
					System.out.println("Add requested");
					String moves = fromServer.replaceAll("ADD\\|", "");
					setBoardState(moves);
					printBoardState(gameboard);
					
					String nextmove = getNextMove();
					System.out.println("Sending: " + nextmove);
					bw.write(nextmove + "\n");
					bw.flush();
					
				} else if (fromServer.startsWith("REJECT")) {
					System.out.println("Move rejected by Server");
					break;
				} else if (fromServer.startsWith("GAME OVER")) {
					System.out.println("Game over");
					break;
				} else {
					System.out.println("New move obtained");
					String[] move = fromServer.split("\\s");
					curr_row = Integer.parseInt(move[0]);
					curr_col = Integer.parseInt(move[1]);
					gameboard[curr_row][curr_col] = Integer.parseInt(move[2]);
				}
			}
		} catch (Exception e) {
			e.printStackTrace();
		}
	}
	
	private String findSquare(String move) {
		
		for (String key:squares.keySet()) {
			ArrayList<String> al = squares.get(key);
			
			if (al.contains(move))
				return key; 
		}
		
		return "";
		
	}


	public String getNextMove() {
		
		String move = "";
		
		if (curr_col == -1 || curr_row == -1) {
			move = getFirstMove();
		} else {
			move = getHeurMove();
			if (move.equals("")) {
				move = getFirstMove();
			}
		}		
		return move;
	}
	
	public ArrayList<String> getChildren(int[][] currboard, int row, int col) {
		ArrayList<String> all_valid_moves = new ArrayList<String>();
			
		curr_row = row;
		curr_col = col;
		
		all_valid_moves.addAll(getRowMoves(currboard));
		all_valid_moves.addAll(getColMoves(currboard));

		System.out.println("For " + row + "," + col + " all moves = " + all_valid_moves.toString());

		
		return all_valid_moves;
		
		
	}
	
	public String getHeurMove() {
		String move = "";
		
		int orig_row = curr_row;
		int orig_col = curr_col;
		
		ArrayList<String> all_children = getChildren(gameboard, curr_row, curr_col);
		
		
		int best_score = 0;
		String best_move="";

		
		int least_children=MAX_ROWS + MAX_COLS;
	
		
		int n = 6;
		if (thisplayer == 1) {
			n = 6;
		} else {
			n = 5;	//player 2
		}
		
		for (String c: all_children) {
			boolean my_move = true;
			//run function n levels deep to find if the child is desirable or not - get score
			//send child with best score
			
			int score = getScore (c, gameboard, my_move, n);	
			
			if (score > best_score) {
				best_score = score;
				best_move = c;
			}
			System.out.println("Move: " + c + " has a score of " + score);
			
		}
		
		if (best_move.equals(""))
			move = getRandomMove();
		else
			move = best_move;
		
		curr_row = orig_row;
		curr_col = orig_col;
		
		return move;
	}
	
	
	public int getScore (String move, int[][] currboard, boolean mymove, int n) {
		
//		System.out.println("Exploring: " + move);
		if (n==0)
			return 0;		
		
		String [] toks = move.split("\\s");
		int row = Integer.parseInt(toks[0]);
		int col = Integer.parseInt(toks[1]);
		int val = Integer.parseInt(toks[2]);
		currboard[row][col] = val;

		
		ArrayList<String> all_children = getChildren(currboard, row, col);
		
		if (all_children.size() == 0) {
			if (mymove)
				return n;
			else
				return (n*-1);
		}
		
		int best_score = -999;
		boolean flag = mymove?false:true;
		for (String c: all_children) {
			int score = getScore (c, currboard, flag, (n-1));
			if (score > best_score) {
				best_score = score;
			}
				
		}
		return best_score;
		
	}
	
	public String getFirstMove() {
		String move = "";
		System.out.println("Need to get a new move. Trying something here");
		for (int i=0;i<MAX_ROWS;i++) {
			for (int j=0;j<MAX_COLS;j++) {
				if (gameboard[i][j] == 0) {
					curr_row = i;
					curr_col = j;
					move = getRandomMove();
					
					if (move.equals("")) {
						System.out.println(i+ "," + j + " didn't work. trying again");
						continue;
					} else {
						System.out.println(i+ "," + j + " successful!");
						return move;
					}
				}
			}
		}
		
		return move;
	}
	
	public String getRandomMove() {
		String move = "";
		ArrayList<String> all_valid_moves = new ArrayList<String>();
		
		all_valid_moves.addAll(getRowMoves(gameboard));
		all_valid_moves.addAll(getColMoves(gameboard));
		
		int max = all_valid_moves.size();
		
		
		if (max > 0) {
			int num = random_int(max);
			move = all_valid_moves.get(num);
		}
		
		
		return move;
	}
	
	public ArrayList<String> getColMoves(int[][] theboard) {
		

		ArrayList<Integer> valid_values = new ArrayList<Integer>();
		ArrayList<Integer> emptyrows = new ArrayList<Integer>();
		
		ArrayList<String> moves = new ArrayList<String>();
		
		for (int i=0;i<MAX_ROWS;i++) {
			valid_values.add(i+1);
		}
		
		for (int i=0;i<MAX_ROWS;i++) {
			if (theboard[i][curr_col] == 0) {
				emptyrows.add(i);
			} else {
				int idx = valid_values.indexOf(theboard[i][curr_col]);
				if (idx > 0)
					valid_values.remove(idx);
			}
		}
		
		for (Integer r: emptyrows){
			for (Integer v:valid_values) {
				moves.add(r + " " + curr_col + " " + v);
			}
		}
		
		ArrayList<String> invalid_moves = new ArrayList<String>();
		
		for (String m: moves) {
			String[] tok = m.split("\\s");
			int row = Integer.parseInt(tok[0]);
			int col = Integer.parseInt(tok[1]);
			int val = Integer.parseInt(tok[2]);
			
			
			for (int i=0; i<MAX_ROWS;i++) {
				if (theboard[row][i] == val || theboard[i][col] == val) {
					invalid_moves.add(m);
				}
			}
			
			String s = findSquare(row + " " + col);
			ArrayList<String> al = squares.get(s);
			
			for (String ss:al) {
				String[] r_c = ss.split("\\s");
				int r = Integer.parseInt(r_c[0]);
				int c = Integer.parseInt(r_c[1]);
				
				if (theboard[r][c] == val) {
					if (!invalid_moves.contains(m)) {
						invalid_moves.add(m);
					}
				}
			}
			
		}
		
		for (String im: invalid_moves) {
			moves.remove(im);
		}
		
//		System.out.println("Possible moves:");
//		for (String m: moves) {
//			System.out.println(m);
//		}
//		
		return moves;
		
	}
	
	public ArrayList<String> getRowMoves(int[][] theboard) {
		ArrayList<Integer> valid_values = new ArrayList<Integer>();
		ArrayList<Integer> empty_cols = new ArrayList<Integer>();
		
		ArrayList<String> moves = new ArrayList<String>();
		
		for (int i=0;i<MAX_COLS;i++) {
			valid_values.add(i+1);
		}
		
		for (int i=0;i<MAX_COLS;i++) {
			if (theboard[curr_row][i] == 0) {
				empty_cols.add(i);
			} else {
//				printBoardState(theboard);
//				System.out.println("curr_row ="+ curr_row + " & col=" + i);
				int idx = valid_values.indexOf(theboard[curr_row][i]);
//				System.out.println("Index = " + idx);
				if (idx > 0)
					valid_values.remove(idx);
			}
		}
		
		for (Integer c: empty_cols){
			for (Integer v:valid_values) {
				moves.add(curr_row + " " + c + " " + v);
			}
		}
		
		ArrayList<String> invalid_moves = new ArrayList<String>();
		
		for (String m: moves) {
			String[] tok = m.split("\\s");
			int row = Integer.parseInt(tok[0]);
			int col = Integer.parseInt(tok[1]);
			int val = Integer.parseInt(tok[2]);
						
			for (int i=0; i<MAX_ROWS;i++) {
				if (theboard[row][i] == val || theboard[i][col] == val) {
					invalid_moves.add(m);
				}
			}
			
			String s = findSquare(row + " " + col);
			ArrayList<String> al = squares.get(s);
			
			for (String ss:al) {
				String[] r_c = ss.split("\\s");
				int r = Integer.parseInt(r_c[0]);
				int c = Integer.parseInt(r_c[1]);
				
				if (theboard[r][c] == val) {
					if (!invalid_moves.contains(m)) {
						invalid_moves.add(m);
					}
				}
			}
			
		}
		
		for (String im: invalid_moves) {
			moves.remove(im);
		}
		
//		System.out.println("Possible moves:");
//		for (String m: moves) {
//			System.out.println(m);
//		}
		
		return moves;
	}

	/**
	 * @param args
	 */
	public static void main(String[] args) {
		if ( args.length != 3 ) {
			System.out.println(
					"usage:  java SudokillPlayer" +
			" <host> <port> <name>" );
			System.exit(1);
		}
		new SudokillPlayer( args[0],Integer.parseInt( args[1] ),args[2]);
	}
	
	public void setBoardState(String moves) {
		String[] rows = moves.split("\\|");
		for (int i=0;i<MAX_ROWS;i++) {
			String[] items = rows[i].split("\\s");
			for (int j=0;j<MAX_COLS;j++) {
				gameboard[i][j] = Integer.parseInt(items[j]);
			}
		}
	}
	
	public void printBoardState(int[][] theboard) {
		for (int i=0;i<MAX_ROWS;i++) {
			for(int j=0;j<MAX_COLS;j++) {
				System.out.print(theboard[i][j] + "\t");
			}
			System.out.println();
		}
	}
	
	public static int random_int(int max) {
		return r.nextInt(max);
	}
	
	
	private void generateSquares() {
		ArrayList<String> sq = new ArrayList<String>();
		sq.add("0 0");
		sq.add("0 1");
		sq.add("0 2");
		sq.add("1 0");
		sq.add("1 1");
		sq.add("1 2");
		sq.add("2 0");
		sq.add("2 1");
		sq.add("2 2");
		squares.put("TL", sq);
		
		sq = new ArrayList<String>();
		sq.add("3 0");
		sq.add("3 1");
		sq.add("3 2");
		sq.add("4 0");
		sq.add("4 1");
		sq.add("4 2");
		sq.add("5 0");
		sq.add("5 1");
		sq.add("5 2");
		squares.put("TC", sq);
		
		sq = new ArrayList<String>();
		sq.add("6 0");
		sq.add("6 1");
		sq.add("6 2");
		sq.add("7 0");
		sq.add("7 1");
		sq.add("7 2");
		sq.add("8 0");
		sq.add("8 1");
		sq.add("8 2");
		squares.put("TR", sq);
		
		sq = new ArrayList<String>();
		sq.add("0 3");
		sq.add("0 4");
		sq.add("0 5");
		sq.add("1 3");
		sq.add("1 4");
		sq.add("1 5");
		sq.add("2 3");
		sq.add("2 4");
		sq.add("2 5");
		squares.put("CL", sq);
		
		sq = new ArrayList<String>();
		sq.add("3 3");
		sq.add("3 4");
		sq.add("3 5");
		sq.add("4 3");
		sq.add("4 4");
		sq.add("4 5");
		sq.add("5 3");
		sq.add("5 4");
		sq.add("5 5");
		squares.put("CC", sq);
		
		sq = new ArrayList<String>();
		sq.add("6 3");
		sq.add("6 4");
		sq.add("6 5");
		sq.add("7 3");
		sq.add("7 4");
		sq.add("7 5");
		sq.add("8 3");
		sq.add("8 4");
		sq.add("8 5");
		squares.put("CR", sq);
		
		sq = new ArrayList<String>();
		sq.add("0 6");
		sq.add("0 7");
		sq.add("0 8");
		sq.add("1 6");
		sq.add("1 7");
		sq.add("1 8");
		sq.add("2 6");
		sq.add("2 7");
		sq.add("2 8");
		squares.put("BL", sq);
		
		sq = new ArrayList<String>();
		sq.add("3 6");
		sq.add("3 7");
		sq.add("3 8");
		sq.add("4 6");
		sq.add("4 7");
		sq.add("4 8");
		sq.add("5 6");
		sq.add("5 7");
		sq.add("5 8");
		squares.put("BC", sq);
		
		sq = new ArrayList<String>();
		sq.add("6 6");
		sq.add("6 7");
		sq.add("6 8");
		sq.add("7 6");
		sq.add("7 7");
		sq.add("7 8");
		sq.add("8 6");
		sq.add("8 7");
		sq.add("8 8");
		squares.put("BR", sq);	
	}
}
