'///////////////////////////////////////////////////////////////////////////////
' Breakedit v0.8
' written by Rene 'retro8x' Breitinger
'
' contact: retro8x@protonmail.com
' support: https://www.paypal.me/retro8x
' license: BMACv1
'          Do whatever you like with this code. However if you make any
'          usage of it then please support me by buying me a coffee.
'
'///////////////////////////////////////////////////////////////////////////////
'
'
#include once "fbgfx.bi"
#include once "vbcompat.bi"
'
using FB
'
' text print function to simplify things. if x is -1 it will center print, if c is -1 it will use a random color
declare sub tPrint (x as integer, y as integer, c as integer, s as string)
declare function messageBox(s as string, style as integer) as boolean
declare function nInput(s as string, length as integer) as integer

'
#define MAXSTAGES 255
'
enum
	STYLE_OK,
	STYLE_YESNO
end enum
'
dim as integer nMouseX, nMouseY, nMouseB		'store our realtime mouse input
'
dim as integer nField(1 to MAXSTAGES, 9, 9) 	'field of 10x10 blocks in 64.pix width and 32.pix height
dim as integer nBlock = 1
dim as integer nCurrentStage 					'in which stage/level we are editing
dim as integer nTotalStages = 1					'total count of existing stages
dim as boolean bQuit							'quits the editor if true
dim as boolean bAddedStage						'to prevent adding a new stage before saved
dim as integer nValidBlocks
dim as boolean bModified
dim as boolean bDoSave
dim as boolean bDiscardChanges
dim as boolean bParseStages = true
'
dim as integer x, y, fh							'helper vars
'
'
'setup our screen and title and positionize, hide and capture mouse
screenres 640, 480, 8,, (GFX_WINDOWED or GFX_NO_SWITCH)
windowtitle "Breakedit v0.8"
'
'
while (1)
	'
	if multikey ( SC_ESCAPE ) or inkey = chr(255) + chr(107) then 
		if nCurrentStage = 0 then 
			bQuit = true
		else
			if bModified then
				if not messageBox ( "STAGE HAS NOT BEEN SAVED YET! DISCARD CHANGES?", STYLE_YESNO ) then 
					bDoSave = true 
				else 
					bDiscardChanges = true
				end if
			else
				bDiscardChanges = true
			end if
		end if
	end if	
	'
	'
	'create a new stage (append)
	if multikey ( SC_N ) then
		if not bAddedStage then
			bModified = false
			nTotalStages += 1
			nCurrentStage = nTotalStages
			nValidBlocks = 0
			bAddedStage = true
			beep
		end if
	end if
	'
	if multikey ( SC_E ) then
		dim as integer n 
		n = nInput ( "TYPE IN THE STAGE NUMBER TO EDIT [1-" + str( nTotalStages ) + "]", len ( str (nTotalStages) ) )
		if n < 1 or n > nTotalStages then
			if not n = -2 then messageBox ( "INVALID STAGE NUMBER!", STYLE_OK )
		else
			nCurrentStage = n
		end if
	end if
	'
	'save stage
	if multikey ( SC_S ) and nCurrentStage > 0 then bDoSave = true
	'
	if multikey ( SC_1 ) then nBlock = 1
	if multikey ( SC_2 ) then nBlock = 2
	if multikey ( SC_3 ) then nBlock = 3
	if multikey ( SC_4 ) then nBlock = 4
	if multikey ( SC_5 ) then nBlock = 5
	if multikey ( SC_6 ) then nBlock = 6
	if multikey ( SC_7 ) then nBlock = 7
	'
	getmouse (nMouseX, nMouseY,, nMouseB)
	'
	'only allow user to perform actions if either edit existing stage or start a new one (append)
	if nCurrentStage > 0 and nMouseY < 320 then
		select case nMouseB
			case 1
				' draw selected block
				bModified = true
				if nField(nCurrentStage, int(nMouseX/64), int(nMouseY/32)) <> nBlock then
					nField(nCurrentStage, int(nMouseX/64), int(nMouseY/32)) = nBlock
					if nBlock > 0 and nBlock < 7 then nValidBlocks += 1 else nValidBlocks -= 1				
				end if
			case 2
				' delete selected block
				bModified = true
				if nField(nCurrentStage, int(nMouseX/64), int(nMouseY/32)) <> 0 then
					nField(nCurrentStage, int(nMouseX/64), int(nMouseY/32)) = 0
					if nBlock > 0 and nBlock < 7 then nValidBlocks -= 1 
				end if
			case 4
				' pick selected block for painting
				nBlock = nField(nCurrentStage, int(nMouseX/64), int(nMouseY/32))
		end select
	end if
	'
	'
	if bDoSave then
		'
		if nValidBlocks > 0 then
			fh = freefile
			open "stages\" + str(nCurrentStage)+".dat" for output as #fh
				for y = 0 to 9
					for x = 0 to 9
						print #fh, nField(nCurrentStage, x, y)
					next
				next
			close fh
			'
			nValidBlocks = 0
			bAddedStage = false
			bDoSave = false
			bModified = false
			nCurrentStage = 0
			messageBox ( "STAGE HAS BEEN SAVED!", STYLE_OK )
		else
			bDoSave = false
			messageBox ( "PUT AT LEAST 1 DESTROYABLE BLOCK IN THE STAGE!", STYLE_OK )
		end if
	end if
	'
	'
	if bDiscardChanges then
		bDiscardChanges = false
		if bAddedStage then 
			'
			for y = 0 to 9
				for x = 0 to 9
					nField(nTotalStages, x, y) = 0
				next
			next			
			'
			nTotalStages -=1	
		end if
		'
		bParseStages = true
		bModified = false
		nValidBlocks = 0
		bAddedStage = false
		nCurrentStage = 0
		beep
	end if
	
	
	if bParseStages then
		'read in our stage data
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
		bParseStages = false
	end if
	'
	'messageBox dialogue
	if bQuit then
		if messageBox ( "ARE YOU SURE YOU WANT TO QUIT?", STYLE_YESNO ) then 
			system
		else
			bQuit = false
		end if
	end if
	'
	'	
	' draw our stuff
	screenlock
	'
	'
	line(0,   0)-(639, 479), 0,   bf															
	line(0, 328)-(639, 329), 244, bf
	line(0, 451)-(639, 454), 41,  bf
	'
	' draw the field 
	if nCurrentStage > 0 then
		for y = 0 to 9
			for x = 0 to 9
				line(x*64, y*32) - (64 + x*64, 32 + y*32), 244, b
				if nField(nCurrentStage, x, y) > 0 then
					'draw the block in the stored color of the playfield index
					line ((1+x*64), (1+y*32))-((x*64)+63, (y*32)+31), nField(nCurrentStage, x, y),bf
				end if
			next
		next
		'
		tPrint ( 5, 59, 15, "[1]     [2]     [3]     [4]     [5]     [6]     [7]" )
		for x = 1 to 7
			color x
			locate 59, x*8
			print chr(254)
		next
		tPrint ( 58, 59, 10, "[S]AVE" )
		tPrint ( 68, 59, 15, "STAGE " + str( nCurrentStage ) )
	else
		'
		'draw stats
		'
		tPrint ( 4, 59, 10,  "TOTAL STAGES FOUND " + str( nTotalStages ) )
		tPrint ( 58, 59, 10, "[E]DIT	[N]EW" )
	end if
	'
	'
	screenunlock
	screensync
	'
	sleep 8, 1
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
'
'
function messageBox(s as string, style as integer) as boolean
	'
	line (120, 200) - (519, 280), 0, bf
	line (120, 200) - (519, 280), 7, b
	line (122, 202) - (517, 278), 7, b
	'
	select case style
		case STYLE_YESNO
			tPrint (-1, 30, 15, s)
			tPrint (-1, 32, 15, "[Y]ES / [N]O" )
			'
			while 1
				if multikey (SC_Y) then beep: return true
				if multikey (SC_N) then beep: return false
				sleep 8, 1
			wend
		case STYLE_OK
			tPrint (-1, 30, 15, s)
			tPrint (-1, 32, 15, "[ENTER]" )
			'
			while 1
				if multikey (SC_ENTER) then beep: return true
				sleep 8, 1
			wend	
	end select
	'
end function

'return -2 on cancel
function nInput(s as string, length as integer) as integer
	'
	dim as integer cursor = 1
	dim in as string
	dim k as string
	dim as boolean kAdd, kDel, kReturn, kCancel
	dim as boolean bDraw = true
	'
	line (120, 200) - (519, 280), 0, bf
	line (120, 200) - (519, 280), 7, b
	line (122, 202) - (517, 278), 7, b
	'
	while 1
		'
		if multikey ( SC_0 ) then 
			kAdd = true: k = "0"
		elseif multikey ( SC_1 ) then 
			kAdd = true: k = "1"
		elseif multikey ( SC_2 ) then 
			kAdd = true: k = "2"
		elseif multikey ( SC_3 ) then 
			kAdd = true: k = "3"
		elseif multikey ( SC_4 ) then 
			kAdd = true: k = "4"
		elseif multikey ( SC_5 ) then 
			kAdd = true: k = "5"
		elseif multikey ( SC_6 ) then 
			kAdd = true: k = "6"
		elseif multikey ( SC_7 ) then 
			kAdd = true: k = "7"
		elseif multikey ( SC_8 ) then 	
			kAdd = true: k = "8"
		elseif multikey ( SC_9 ) then 
			kAdd = true: k = "9"
		elseif multikey ( SC_BACKSPACE ) then
			kDel = true
		elseif multikey ( SC_ENTER ) then 
			kReturn = true
		elseif multikey ( SC_ESCAPE ) then 
			kCancel = true
		end if	
		'
		'
		if kAdd or kDel then sleep 64, 1
		if kCancel or kReturn then sleep 128, 1
		'
		if kDel and cursor > 0 then
			bDraw = true
			cursor -=1
			if cursor = 0 then cursor = 1
			in = left( in, cursor-1 )			
			kDel = false
			k = ""
		end if
		'
		if kAdd and cursor <= length then
			cursor += 1
			in += k
			k = ""
			kAdd = false
		end if
		'
		if kReturn then
			if len( in ) = 0 then 
				return 0
			else
				return val( in )
			end if
		end if
		'
		if kCancel then return -2
		'
		if bDraw then
			line (120, 200) - (519, 280), 0, bf
			line (120, 200) - (519, 280), 7, b
			line (122, 202) - (517, 278), 7, b
			bDraw = false
		end if
		'
		tPrint (-1, 30, 15, s)
		tPrint (-1, 32, 15, ">" + in )
		'
		'
		screensync
		wait 8, 1
		'
	wend
	'
end function
