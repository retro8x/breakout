#include once "fbgfx.bi"
#include once "windows.bi"
#include once "win/mmsystem.bi"
#include once "vbcompat.bi"
'
using FB
'
' text print function to simplify things. if x is -1 it will center print, if c is -1 it will use a random color
declare sub tPrint (x as integer, y as integer, c as integer, s as string)
'
#define BALLRADIUS		  8
#define PADDLESIZE		 80
#define VELOCITY		  5
#define MAXSTAGES		255
#define VERSION			"1.5"
#define MAX_PARTICLES	16
'
'particle system
type particle
	colour as integer
	x as integer
	y as integer
end type
dim pt(1 to MAX_PARTICLES) as particle
dim as integer ptCount
'
dim as integer nMouseX, nMouseY,nMouseB			'store our realtime mouse input
'
dim as boolean bLaunched						'has the player launched a ball to the playfield?
dim as integer nPaddleX							'pixel x position at center 
dim as double  fBallX, fBallY					'pixel position of ball (center)
dim as double  fBallPrevX, fBallPrevY
dim as double  fBallDeltaX, fBallDeltaY			'handle our balls velocity
dim as double  fBallAngle
'
dim as integer nField(1 to MAXSTAGES, 9, 9) 	'field of 10x10 blocks in 64.pix width and 32.pix height
dim as integer nGridX, nGridY
dim as integer nGridPrevX, nGridPrevY
dim as integer nBrick, nPrevBrick				'return the block we have hit
'
dim as integer nCombo, nBalls = 3				'some player stats
dim as double  fHiScore (1 to MAXSTAGES)
dim as double  fScore					
dim as double  fTotalScore, fTotalHiScore		
dim as integer nCurrentStage 					'in which stage/level we are playing
dim as integer nTotalStages 					'total count of existing stages
dim as boolean bStageClear						'flag wheter we have finished the stage or not yet
dim as boolean bAnnounceNewHiscore				'if true display new highscore on stage finish
dim as boolean bAnnounceNewTotalHiScore			'if true display new TOTAL highscore of the full game
dim as boolean bQuit							'quits the game if true
dim as boolean bLoadData = true					'do we have to reload the stages and scores?
dim as boolean bSound = true					'if sound is enabled or not
'
dim as double fTimeElapsed, fSystemTimer
dim as double fTimeOut
'
dim as integer x, y, fh							'helper vars
'
'

'
'read in the total highscore
fh = freefile
if not fileexists ("records\total.rec") then
	open "records\total.rec" for output as #fh
		print #fh, 0
	close #fh
else
	open "records\total.rec" for input as #fh
		input #fh, fTotalHiScore
	close #fh
end if
'
'setup our screen and title and positionize, hide and capture mouse
screenres 640, 480, 8,, (GFX_WINDOWED or GFX_NO_SWITCH)
setmouse 320, 436, 0, 1
windowtitle "Breakout v" + VERSION
'
randomize timer
'
while (1)
	fSystemTimer = timer
	'
	if multikey ( SC_ESCAPE ) then bQuit = true
	
	if multikey ( SC_G ) and multikey ( SC_O ) and multikey ( SC_D ) then nBalls = 99
	if multikey ( SC_S ) then bSound = not bSound: sndPlaySoundA("sound\bounce.wav", 0)
	getmouse (nMouseX, nMouseY,, nMouseB)
	nPaddleX = nMouseX
	
	if bLoadData then
		'read in our stage data
		nCurrentStage = 1
		nTotalStages = 1
		while fileexists ( "stages\" + str(nTotalStages)+".dat" ) and nTotalStages < MAXSTAGES
			fh = freefile
			open "stages\" + str(nTotalStages)+".dat" for input as #fh
				for y = 0 to 9
					for x = 0 to 9
						input #fh, nField(nTotalStages, x, y)
					next
				next
			close fh
			nTotalStages +=1
		wend
		nTotalStages -= 1
		'
		'oops no stages exist?!
		'let's create a random one =)
		if nTotalStages = 0 then
			nTotalStages +=1
			for y = 0 to 9
				for x = 0 to 9
					nField(nTotalStages, x, y) = int(rnd*7)+1
				next
			next
		end if
		
		'read in our highscores, if not exist, create empty one
		for x = 1 to nTotalStages
			fh = freefile
			if not fileexists ( "records\" + (str(x)+".rec") ) then
				open "records\" + str(x)+".rec" for output as #fh
					print #fh, 0
				close #fh
				fHiScore(x)=0
			else
				open "records\" + str(x)+".rec" for input as #fh
					input #fh, fHiScore(x)
				close #fh
			end if
		next
		
		bLoadData = false
	end if
	'		
	'check if player wants to launch a ball
	if nMouseB > 0 and not bLaunched and nBalls > 0 and nCurrentStage <= nTotalStages then				
		bLaunched = true
		bAnnounceNewHiscore = false
		if bSound then sndPlaySoundA("sound\launch.wav", 1)
		nCombo = 0
		if nPaddleX<630 then fBallX = nPaddleX + BALLRADIUS else fBallX = nPaddleX - BALLRADIUS
		fBallY = 420 - ( BALLRADIUS * 2 )
		fBallAngle = 0.165 * 3.1415926 * 2.0
		fBallDeltaX = cos(fBallAngle)
		fBallDeltaY = Sin(fBallAngle)
		ptCount = 0
	elseif nMouseB > 0 and nBalls = 0 then
		nBalls = 3
		bLoadData = true
		fScore = 0
		fTotalScore = 0
		bLaunched = false
		if bSound then sndPlaySoundA("sound\relaunch.wav", 0)
	end if
	'
	'if we win the stage, advance and reward player, if game over update the score records!
	'note: we need to check for bLaunched here too, else this will continue after game over!
	'also check for exiting the game here, so the records do not get lost
	if  ( ( (bStageClear) orelse cbool(nBalls = 0) ) andalso bLaunched ) orelse bQuit then
		bLaunched = false
		'check if we need to update the hiscore
		if fScore > fHiScore(nCurrentStage) then
			fh = freefile
			open "records\" + str(nCurrentStage) + ".rec" for output as #fh
				print #fh, fScore
			close #fh
			if bSound then sndPlaySoundA("sound\hiscore.wav", 1)
			bAnnounceNewHiscore = true
		else
			if nBalls > 0 and bSound then sndPlaySoundA("sound\clear.wav", 1) 'in case we won the stage only
		end if
		'
		' only proceed in case we are not gameover and not quitting the game
		if nBalls > 0 and not bQuit then
			fscore = 0		'reset our stage score counter
			if nBalls < 10 then nBalls += 1	
			nCurrentStage += 1
			ptCount = 0
		end if
		'
		'check if we need to update the TOTAL hiscore, either on beating the final stage or by quitting
		if ( nCurrentStage > nTotalStages or bQuit ) and fTotalScore > fTotalHiScore then
			fh = freefile
			open "records\total.rec" for output as #fh
				print #fh, fTotalScore
			close #fh
			if bSound then sndPlaySoundA("sound\hiscore.wav", 1)
			bAnnounceNewTotalHiScore = true
		end if
		'
		if bQuit then system
	'	
	end if
	'
	'check that paddle not moves out of screen
	if nPaddleX < (PADDLESIZE/2)+5 then 
		nPaddleX =(PADDLESIZE/2)+5 				'our paddleX is at center of the paddle
	elseif nPaddleX > 639-(PADDLESIZE/2)-5 then 
		nPaddleX = 639-(PADDLESIZE/2)-5			'so we need to keep a spacing to the screens edges by half its size
	end if	
	
	'handle particles
	for x = 1 to ptCount
		'check if the particle has to be removed from the list
		if pt(x).y > 470 then
			pt(x).colour = pt(ptCount).colour
			pt(x).x = pt(ptCount).x
			pt(x).y =  pt(ptCount).y
			ptCount-= 1
		end if
		pt(x).x += -5 + int(rnd*10)
		pt(x).y += VELOCITY*2
	next
	'
	'when our ball is active then check for its movement and colissions
	if bLaunched then
		'		
		'check for boundaries
		if (fBallX > 639-BALLRADIUS - 1) or (fBallX < 0 + BALLRADIUS + 1) then 
			fBallDeltaX =  fBallDeltaX * -1
			if bSound then sndPlaySoundA("sound\bounce.wav", 1)
		end if
		
		if fBallY < 0 + BALLRADIUS + 1 then 
			fBallDeltaY =  fBallDeltaY * -1		'top frame
			if bSound then sndPlaySoundA("sound\bounce.wav", 1)
		end if
		'
		'cap max delta
		if fBallDeltaX < -1.8 then fBallDeltaX = -1.8 
		if fBallDeltaX >  1.8 then fBallDeltaX =  1.8
		if fBallDeltaY < -1.8 then fBallDeltaY = -1.8
		if fBallDeltaY >  1.8 then fBallDeltaY =  1.8
		'				
		'store our previous ball position
		fBallPrevX = fBallX
		fBallPrevY = fBallY
		'update our balls position
		fBallX += fBallDeltaX * VELOCITY
		fBallY += fBallDeltaY * VELOCITY
		'
		'check if we hit an object
		'
		'first check if we are even inside the grid!
		if fBallY < 320 then
			'reset our previous results
			nBrick = nPrevBrick = 0
			'get where we have been on the grid
			nGridPrevX = int(fBallPrevX/64)
			nGridPrevY = int(fBallPrevY/32)
			'get where we are NOW inside the grid
			nGridX = int(fBallX/64)
			nGridY = int(fBallY/32)
			'return the values from the field
			nBrick = nField(nCurrentStage, nGridX, nGridY)
			nPrevBrick = nField(nCurrentStage, nGridPrevX, nGridPrevY)
			'if its not black (nothing)
			if nBrick > 0	then	
				'do whatever the blocks hit is about
				select case nBrick
				case 1 to 4 : nField(nCurrentStage, nGridX, nGridY) = 0
				case 5	    : nField(nCurrentStage, nGridX, nGridY) = 4
				case 6		: nField(nCurrentStage, nGridX, nGridY) = 5
				end select
				'
				'reflect velocity
				if nGridX <> nGridPrevX then fBallDeltaX = (fBallDeltaX * -1) + rnd*(-0.2)+0.1
				if nGridY <> nGridPrevY then fBallDeltaY = (fBallDeltaY * -1) + rnd*(-0.2)+0.1
				'
				if nbrick < 7 then
					'update combo and score, play sfx (if its no hard block)
					nCombo +=1
					fTotalScore += 5*(nBrick*nCombo)
					fScore += 5*(nBrick*nCombo)	
					if bSound then 
						if nCombo = 2 then
							sndPlaySoundA("sound\combo1.wav", 1)
						elseif nCombo = 6 then
							sndPlaySoundA("sound\combo2.wav", 1)
						else
							sndPlaySoundA("sound\break.wav", 1)
						end if
					end if
					
					fTimeOut = timer 'reset the timeout timer
					
					if ptCount < MAX_PARTICLES then
						ptCount+=1
						pt(ptCount).colour = nBrick
						pt(ptCount).x = nGridX*64
						pt(ptCount).y = nGridY*32
					end if
					'
				else
					'hard blocks only do a noise
					if bSound then sndPlaySoundA("sound\solid.wav", 1)
				end if
				
			end if
			
		end if
		'
		'check if we hit the paddle
		if fBallY > 420 - ( BALLRADIUS * 2 ) then 
			'we are inside the paddles range
			if fBallX >= nPaddleX - ( PADDLESIZE / 2 ) - BALLRADIUS and fBallX <= nPaddleX + ( PADDLESIZE / 2 ) + BALLRADIUS then
				'mirror Ydelta and add/sub Xdelta to the side depending where we hit the paddle
				fBallDeltaY = -fBallDeltaY
				fBallDeltaX += (fBallX-nPaddleX) * 0.05
				nCombo = 0
				if bSound then sndPlaySoundA("sound\bounce.wav", 1)
				fTimeOut = timer 'reset the timeout timer
			else 'we missed, let player fire another ball
				bLaunched = false
				nBalls -= 1
				if nBalls > 0 then 
					if bSound then sndPlaySoundA("sound\miss.wav", 1)
					fScore -= 50
					if fScore < 0 then fScore = 0
				else
					if bSound then sndPlaySoundA("sound\gameover.wav", 1)
				end if
			end if
		end if
		'			
		
		'the ball perhaps got stuck in a cycle =), let player refire the ball after 12 seconds, without loosing a life
		if timer - fTimeOut > 15 then
			bLaunched = false
			if bSound then sndPlaySoundA("sound\relaunch.wav", 1)
		end if
			
	end if	
	'	
	'	
	' draw our stuff as long as we are on a valid stage yet =) 
	screenlock
	if nCurrentStage <= nTotalStages then
		'
		line(0,   0)-(639, 479), 0,   bf															'wipe block area
		line(0, 328)-(639, 329), 244, bf															'non block area trim
		line(0, 441)-(639, 444), 41,  bf															'score area trim
		'paddle
		line(nPaddleX - (PADDLESIZE/2)+4, 420+4) - (nPaddleX + (PADDLESIZE/2)+4, 436+4), 100, bf	'draw our paddles shade in an offset down right
		line(nPaddleX - (PADDLESIZE/2)+2, 420+3) - (nPaddleX + (PADDLESIZE/2)+2, 436+2), 105, bf	'draw our paddles shade in an offset down right
		line(nPaddleX - (PADDLESIZE/2),     420) - (nPaddleX + (PADDLESIZE/2),     436), 4,   bf	'draw our paddle which is 32.pix in height.
		line(nPaddleX - (PADDLESIZE/2),     420) - (nPaddleX + (PADDLESIZE/2)-2,   434), 40,  bf	'draw our paddle which is 32.pix in height.
		line(nPaddleX - (PADDLESIZE/2)+1,   422) - (nPaddleX + (PADDLESIZE/2)-1,   424), 42,  bf	'draw a colored line on the paddle
		'
		' draw the blocks remaining and check for stage clear
		' checking for game logic within the draw routine might be sloppy but
		' it saves us a whole cycle through the grid again
		bStageClear = true
		for y = 0 to 9
			for x = 0 to 9
				if nField(nCurrentStage, x, y) > 0 then
					'first draw the dark block in an offset
					line ((x*64)+2, (y*32)+2)-((x*64)+64, (y*32)+32), nField(nCurrentStage, x, y),bf
					'draw the block in the stored color of the playfield index
					line ((x*64), (y*32))-((x*64)+62, (y*32)+30), nField(nCurrentStage, x, y)+8,bf
					'also at least one block still remains, so set our stage clear back to false, 7 are solid blocks!
					if nField(nCurrentStage, x, y) < 7 then bStageClear = false
				end if
			next
		next
		'
		'draw particles
		if bLaunched then
			for x = 1 to ptCount
				line (pt(x).x+2, pt(x).y+2)-(pt(x).x+64, pt(x).y+32), pt(x).colour, b
				'draw the block in the stored color of the playfield index
				line (pt(x).x, pt(x).y)-(pt(x).x+62, pt(x).y+30),pt(x).colour+8,b
			next
		end if
		'
		'draw the ball only if not missed by paddle and it is launched,
		'if its not launched it would draw a ball in top left corner on start.
		if ( fBallY < 450 - BALLRADIUS ) and bLaunched then
			circle(fBallX+(int(BALLRADIUS/2)), fBallY+(int(BALLRADIUS/2))), BALLRADIUS, 105		'draw balls shadow
			paint(fBallX+(int(BALLRADIUS/2)), fBallY+(int(BALLRADIUS/2))), 105, 105
			circle(fBallX, fBallY), BALLRADIUS, 40												'draw the ball
			paint(fBallX, fBallY), 40, 40
			circle(fBallX-(int(BALLRADIUS/3)), fBallY-(int(BALLRADIUS/3))), BALLRADIUS/3, 42	'draw a shine
			paint(fBallX-(int(BALLRADIUS/3)), fBallY-(int(BALLRADIUS/3))), 42, 42	
		end if
		'
	else 'we finished the last stage
		'
		tPrint ( -1, 48, -1, "CONGRATULATION! YOU BEAT THE GAME!!!" )
	
		if bAnnounceNewTotalHiScore  then tPrint ( -1, 51, -1, "NEW TOTAL HI-SCORE!" )	
		'
	end if
	'
	'draw stats
	if bLaunched or nBalls = 0 then
		if nBalls = 0 then tPrint ( -1, 48, 14, "GAME OVER" )
		'
		tPrint ( 4, 58, 10,  "TOTAL SCORE " + str(fTotalScore) )
		tPrint ( 4, 59,  2,  "PERS. BEST  " + str(fTotalHiScore) )
		tPrint ( 30, 58, 10, "STAGE SCORE " + str(fScore) )
		tPrint ( 30, 59,  2, "PERS. BEST  " + str(fHiScore(nCurrentStage) ) )
		tPrint ( 53, 59, 40, chr(3)+" "+ str(nBalls) )
		tPrint ( 60, 59, 10, "STAGE " + str(nCurrentStage) )
		if bSound then tPrint ( 71, 59, 14, "[S]FX "+chr(14) )
		if nCombo > 1 and nBalls > 0 then 
			if nCombo < 6 then tPrint (-1, 48, nCombo - 1 + 8, "COMBO X "+ str(nCombo) ) else tPrint (-1, 48, -1, "COMBO X "+ str(nCombo) )
		end if
		'
	else
		'
		if bAnnounceNewHiscore then tPrint ( -1, 50, -1, "NEW HI-SCORE!" )
		if nCurrentStage<=nTotalStages then tPrint ( -1, 59, 15, "--PRESS MOUSE BUTTON TO START--" ) 
	'
	end if
	'
	screenunlock
	screensync
	'
	fTimeElapsed = timer - fSystemTimer			'get time that one cycle took
	if fTimeElapsed < 0 then 
		fTimeElapsed = 0 						'should not happen
	elseif fTimeElapsed > 7 then 
		fTimeElapsed = 7						'can't imagine this but well...
	end if
	sleep 8 - fTimeElapsed						'save cpu usage and smooth things out
wend
'
'subroutine to output a text
'///////////////////////////
sub tPrint (x as integer, y as integer, c as integer, s as string)
	if x = -1 then x =40 - (len(s) / 2)		'center print
	if c = -1 then c = int( rnd * 14 ) + 1	'random color
	locate y, x
	color c
	print s	
end sub

