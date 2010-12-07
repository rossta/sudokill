Sudoku

I was introduced to Sudoku when my 12 year-old asked me to solve
the most challenging one in a book while on a train.
Because attempting a solution
on a moving train made me slightly sick,
I resolved to solve the game by programming.
Three hours and 100 lines of programming later, my program could solve
the hardest Sudoku puzzles I found on the web in two seconds.
I'm not boasting. The current record that I know of is by Arthur
Whitney in his programming language q. It's 103 [italics] characters 
[end italics] long. 
Now, I do not advocate short program contests,
because I think they lead to incomprehensible code, 
but I do find this impressive.

Let's study this as an elimination puzzle.
The target state is to fill
a 9 by 9 grid with digits between 1 and 9. 
Each digit should appear exactly once in each row,
once in each column, and once in each non-overlapping three by three box
starting from the upper left corner.

Warm-Up:

In the following, we use 0 to represent blank.

[Ed: each of these should be on one page with format
preserved; that is, crossing pages 
is not allowed]

 0 0 0 0 0 0 0 0 7
 7 0 4 0 0 0 8 9 3
 0 0 6 8 0 2 0 0 0
 0 0 7 5 2 8 6 0 0
 0 8 0 0 0 6 7 0 1
 9 0 3 4 0 0 0 8 0
 0 0 0 7 0 4 9 0 0
 6 0 0 0 9 0 0 0 0
 4 5 9 0 0 0 1 0 8

Let's look at the lower left box in context:

 0 0 0 
 7 0 4 
 0 0 6 
 0 0 7 
 0 8 0 
 9 0 3 
 0 0 0 7 0 4 9 0 0
 6 0 0 0 9 0 0 0 0
 4 5 9 0 0 0 1 0 8

We know that of the five zeroes present in the lower left box, one must be
7 and one must be 8.
Because there is a 7 on the row that is third from bottom, none of the
top zeroes can be changed to a 7.
Because there is a 7 in the third column, the only place for a 7 is to the
right of the 6 yielding:

 0 0 0 
 7 0 4 
 0 0 6 
 0 0 7 
 0 8 0 
 9 0 3 
 0 0 0 7 0 4 9 0 0
 6 7 0 0 9 0 0 0 0
 4 5 9 0 0 0 1 0 8

This now implies, in the right lower box, that the 7 must
be on the last row, yielding

 0 0 0 7 0 4 9 0 0
 6 7 0 0 9 0 0 0 0
 4 5 9 0 0 0 1 7 8

Working an example by hand often suggests an algorithm.
That is the case here.
Start by annotating each 0 by
the values it could have.
Those are the constraints on that position.
Whenever a 0 can have only one value, replace it by that
value and recompute the constraints on all other 0s.

Let's do this starting from the puzzle as it now stands:

 0 0 0 0 0 0 0 0 7
 7 0 4 0 0 0 8 9 3
 0 0 6 8 0 2 0 0 0
 0 0 7 5 2 8 6 0 0
 0 8 0 0 0 6 7 0 1
 9 0 3 4 0 0 0 8 0
 0 0 0 7 0 4 9 0 0
 6 7 0 0 9 0 0 0 0
 4 5 9 0 0 0 1 7 8

Start with the top left corner 0 and give its context:

 0 0 0 0 0 0 0 0 7
 7 0 4 
 0 0 6 
 0 
 0 
 9 
 0 
 6 
 4 

That entry can be any number between 1 and 9 provided it is not
4, 6, 7, or 9.
That is, it could be 1, 2, 3, 5, or 8.
This is not very constraining.
Let us next consider the middle entry of the upper left box: 

 0 0 0 
 7 0 4 0 0 0 8 9 3
 0 0 6 
   0 
   8 
   0 
   0
   7
   5

It cannot be 3, 4, 5, 6, 7, 8, 9.
So, it is limited to 1 or 2.
That is better, but not great yet.

Next consider the top left entry of the middle left box:

 0 
 7 
 0 
 0 0 7 5 2 8 6 0 0
 0 8 0 
 9 0 3 
 0 
 6 
 4 

the following are excluded: 2, 3, 4, 5, 6, 7, 8, 9.
So this value must be 1, yielding a new state:

 0 0 0 0 0 0 0 0 7
 7 0 4 0 0 0 8 9 3
 0 0 6 8 0 2 0 0 0
 1 0 7 5 2 8 6 0 0
 0 8 0 0 0 6 7 0 1
 9 0 3 4 0 0 0 8 0
 0 0 0 7 0 4 9 0 0
 6 7 0 0 9 0 0 0 0
 4 5 9 0 0 0 1 7 8

Now, let's look just to the right of that entry
Here is the context:

   0 
   0 
   0 
 1 0 7 5 2 8 6 0 0
 0 8 0 
 9 0 3 
   0 
   7 
   5 

This excludes 1, 2, 3, 5, 6, 7, 8, 9.
So this forces a choice of 4.
(We can use more context sometimes such as the fact
that the first column has a 4, thus precluding a 4 from replacing the 0
between the 1 and the 9, but don't try such reasoning in a moving train.)
Go ahead. Try to solve this one.
You'll see that it's pretty easy.



Solution to Warm-Up.

 8 1 5 3 4 9 2 6 7
 7 2 4 6 5 1 8 9 3
 3 9 6 8 7 2 4 1 5
 1 4 7 5 2 8 6 3 9
 5 8 2 9 3 6 7 4 1
 9 6 3 4 1 7 5 8 2
 2 3 1 7 8 4 9 5 6
 6 7 8 1 9 5 3 2 4
 4 5 9 2 6 3 1 7 8

End of Warm-Up

In the warm-up puzzle, there was always at least
one entry which was constrained to a single
value.
That is, we were never tempted to "speculate" -- assign a value
to an entry that is consistent with the constraints, but is not unique,
and then explore the implications.
Some Sudoku puzzles encourage speculative behavior, though purists
take pride in finding solutions without speculation.

Here is the pseudo-code without speculation:


 proc basicsud(state s)
  stillchanging:= true
  while stillchanging
   stillchanging:= false
   find constraints for each entry currently represented by a 0 in s
   if there is only one possible value v for some entry e
	then 
           assign v to e in s
           stillchanging:= true
   end if
   if there is an entry e with no possible values
	then return "inconsistent state"
   end if
  end while
  return s
 end proc

The above routine not only works for easy Sudokus, it is
also the workhorse for the harder ones.
The only thing we've added is a 
test for the inconsistent case. 
This might arise say when the row and the column of an entry
together already include all numbers between 1 and 9.
We'll need this test for when we speculate.

How does speculation work?
Let's start with the intuition.
Assume that we have a consistent state to begin with.
We call basicsud. 
If this leads to a complete state (one with every blank/zero
entry replaced by a number), then we are done.
If we reach a point where every blank entry has two or more possible
values, we systematically try
the possible values for each entry. 
That is, for each current blank, save the current state, then
try one of its values.
If that attempt (or speculation) leads to an inconsistent state,
then restore the state before the speculation and try another value.

The pseudo-code makes use of a stack in which we save
states as we go.
When we're about to speculate, we push a state onto the stack.
If the speculation doesn't work, we pop the top state from the stack.

 proc specsud(state s)
    s':= basicsud(s)
    if s' == "inconsistent state" then return "inconsistent state"
    if s' is complete then return s' 
     else 
      let R be the entries in s' having two or more possible values
      for each entry e in R
        let V be the possible values for e
        for each value v in V
           push s' on the stack of saved states
           s'':= s' with the assignment of v to e
           s''':=  specsud(s'') 
           if s''' is complete then return s''' end if
           pop s'
        end for
      end for
    end if
 end proc specsud
          
This algorithm is easy to program in almost every language and
the result is really fast. 
See if you can solve this problem in three seconds or less
on a reasonable personal computer.
The 103 character program I referred to above takes under 100 milliseconds,
but this is not a race.
Really. It's not.

