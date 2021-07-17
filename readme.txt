'//////////////////////////////////////////////////////////////////////////////
' Breakout v1.5 / Breakedit v0.8
' written by Rene 'retro8x' Breitinger
'
' discord: retro8x#3765
' support: https://www.paypal.me/retro8x
' license: BMACv1
'          Do whatever you like with this code. However if you make any
'          usage of it then please support me by buying me a coffee.
'
' The sound effects are made by 'rubberduck' under the CC0 license
'//////////////////////////////////////////////////////////////////////////////
'

compile:
you will need the freebasic (fbc) compiler 32-bit

windows:
to compile the game run "fbc -s gui breakout.bas"
to compile the editor run "fbc -s gui breakedit.bas"




Breakout, a very classic game! Move the Paddle using the mouse and destroy the 
blocks with the floating ball. Press any mouse button to launch the ball. 
If you hit all the blocks then you will come to the next stage. will you be 
able to master them all? but take care of your balls!
have fun!

HINT:
=====
- If the ball just doesn't want to come back down keep calm!
  You will get your next chance after 15 seconds.
- There exist a secret key combination for some extra balls, hehehe :>

GAME:
=====
Press any mouse button to launch the ball
use the mouse to move the paddle left or right
press 'S' to enable/disable sound effects
press 'ESC' to end the game

EDITOR:
=======
In the editor 'breakedit.exe' you can edit existing stages or 
add new ones, up to 255! However the keys are kind of self explaining. 
Just follow the Textline at the bottom and the dialogue windows. 
Press number 1-7 to select a block for drawing.
Note that 7-white block are solid ones.

the blocks: 
1-4 takes one hit
5 takes 2 hits
6 takes 3 hits
7 is solid

-left mouse button to put a block
-right mouse button to erase a block
-mid mouse button will select the block at mouse position 
 to draw with (instead pressing 1-7)

NOTE:
-you can delete your saved highscores by executing 
 the batch file 'reset_scores.bat'

changelog:
==========
v1.5
- allow up to 255 stages in total
- redesign stats drawing
- option to disable sound effects
- redesign stages
- restart game after game over
- blocks fall after hitting them
- let player relaunch the ball after 12 seconds, in case it got stuck
- add stage editor
- introduce multihit blocks and solid blocks
- fix wrong bounce off directions
- working with angle and deltas now, much more realistic and controllable
- code optimize
- if not stage exists, create one random filled 
  just to the memory without writing it to the disk


v1.35
- absolute smooth drawings due to sync
- optimized code (only call if needed, colission)
- little more clear bricks design
v1.3
- improve ball and paddle design
- remove double checking for balls bounds
- add autocreate of stage 1 in case user deleted all stages
- slightly increase ballsize (looks more round)
- fix trimline count as hitdetection
- moved gamefiles to subdirectories
- save records also on mid game exit
- instantly update total score in the display
v1.2
- dont give more than 9 balls
- dont allow negative score
- added trim lines
- add stage score to total score on gameover
- realigned announcement text
- several tiny (potential) bugfixes
- added highscore for every stage
- added total highscore
- substract points when loose a ball
- changed sound fx
- added sound fx for stage clear
- added sound fx for certain combo
- added sound fx for gameover
- colorize combo fontcolor depending on combo amount
- fixed combo bug, combo wasnt reset on a ball loss
- simplified some game code
- exported leveldata into files

v1.15
- smooth things out, consistant delay of the game calculated by
  elapsed time of gamecycle

v1.1
- added sound
- added shadows
- improved collision
- added combo multiplier for score
- redesigned and added stages, 7 in total
- added control of velocity to the paddle
- fine tunings overall
