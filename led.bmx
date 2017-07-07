Rem

****************************************************
Pinlandia - LED.BMX
****************************************************

****************   Details   ***********************

	- What is it?:      MPF LED show script generator
	- Language:         Blitxmax
	- Programmed by:    Mark Incitti - 2017

****************    TODO     ***********************
	- FPS selector
	- code refactor - move functions into types


****************  History  *************************

- V1.53 - 2017/07/07
	- code cleanup

- V1.52 - 2017/07/07
	- better behaviour when switching segments
	- U key plays current segment
		
- V1.51 - 2017/07/06
	- changed to 30 fps (previous are set to 60)

- V1.5 - 2017/07/06 (not released)
	- Load/save, etc

- V1.0 - 2017/07/05
	- initial release

End Rem

Strict

Framework BRL.GlMax2D

Import BRL.System
Import BRL.Basic
Import BRL.pngloader
Import BRL.pixmap
Import BRL.Retro

AppTitle$ = "Pinlandia - V1.52 - 2017-07-07"

SetGraphicsDriver GLMax2DDriver()


Global framerate:Int = 30
Global ms_per_frame:Int = 33

Graphics 800, 800, 0
SetClsColor 0, 0, 0

Const cMAXLEDS = 256
Const cMAXANIMS = 256
Const cMAXIMAGES = 1000
Const cDURATION = 1023
Const cSTARTX = 50+150
Const cSTARTY = 50+300

Global pixColor:appColor = New appColor
Global num_leds = 0
Global ledarray:led[]
ledarray = New led[cMAXLEDS]
SetUpLeds()

Global num_images:Int = 0
Global images:TImage[]
images= New TImage[cMAXIMAGES]
Global image_filename$[cMAXIMAGES]
LoadImages()

Global anim_array:animation[]
anim_array = New animation[cMAXANIMS+1]
animation.CreateAnimations()
Global bufferAnim:animation = New animation

Global anim_index = 0
Global cur_an:animation = anim_array[anim_index]
cur_an.active = 1

Global se:Int = 1

Global g_rot = 0
Global g_sc_x:Float = 0.5
Global g_sc_y:Float = 0.5
Global g_cl_r = 200
Global g_cl_g = 128
Global g_cl_b = 200
Global first_step:Int  = 0

Global animate:Int = 0
Global animate_current:Int = 0
Global flash:Int = 0

Global g_fh:TStream
Global g_write_to_file:Int = 0

Local col_start_x = 650
Local col_start_y = 490
Local col_end_x = col_start_x + 80




'-- main loop  ---------------------------------------------------------------------------------------------------

Repeat

	Cls

	Local mult:Int = 1
	Local shift:Int = 0
	If KeyDown(KEY_LCONTROL) Or KeyDown(KEY_RCONTROL)
		mult = 10
	EndIf

	If KeyDown(KEY_LSHIFT) Or KeyDown(KEY_RSHIFT)
		shift = 1
	EndIf

	If KeyHit(KEY_I)
		flash = 60*4
	EndIf

	If KeyHit(KEY_A)
		If shift = 1
			g_rot = g_rot-2*mult
		Else
			g_rot = g_rot+2*mult
		EndIf
		cur_an.set_rotation(g_rot,se)
	EndIf
	
	If KeyHit(KEY_S)
		If shift = 1
			g_sc_x = g_sc_x - 0.025*mult
		Else
			g_sc_x = g_sc_x + 0.025*mult
		EndIf
		cur_an.set_scale_x(g_sc_x,se)
	EndIf

	If KeyHit(KEY_X)
		If shift = 1
			g_sc_y = g_sc_y - 0.025*mult
		Else
			g_sc_y = g_sc_y + 0.025*mult
		EndIf
		cur_an.set_scale_y(g_sc_y,se)
	EndIf

	If KeyHit(KEY_C)
		If shift = 1
			g_sc_x = g_sc_x - 0.025*mult
			g_sc_y = g_sc_y - 0.025*mult
		Else
			g_sc_x = g_sc_x + 0.025*mult
			g_sc_y = g_sc_y + 0.025*mult
		EndIf
		cur_an.set_scale_x(g_sc_x,se)
		cur_an.set_scale_y(g_sc_y,se)
	EndIf

	If KeyHit(KEY_T)
		cur_an.cycle_image()
	EndIf

	If MouseHit(1)
		Local mx = MouseX()
		Local my = MouseY()

		If mx < 400
			cur_an.set_position( MouseX(), MouseY(), se)
		Else
			'menu stuff
			If mx > 650
				'ON/OFF
				If my > 10 And my < 20
					cur_an.active = 1-cur_an.active
				EndIf
			
				'START/END
				If my > 30 And my < 40
					se = 1-se
					If se = 1
						cur_an.set_cur_to_start() 
					Else
						cur_an.set_cur_to_end() 
					EndIf
				EndIf
				
				'DELAY
				If my > 50 And my < 60
					If mx < 690 
						cur_an.delaysteps = cur_an.delaysteps - 1*mult
						If cur_an.delaysteps < 0 Then cur_an.delaysteps  = 0
					Else
						cur_an.delaysteps = cur_an.delaysteps + 1*mult
						If cur_an.delaysteps >1000 Then cur_an.delaysteps  = 1000
					EndIf
				EndIf
				
				'TIME
				If my > 70 And my < 80
					If mx < 690 
						cur_an.duration = cur_an.duration - ms_per_frame*mult
						If cur_an.duration < MS_PER_FRAME Then cur_an.duration = MS_PER_FRAME 
					Else
						cur_an.duration = cur_an.duration + ms_per_frame*mult
						If cur_an.duration >30000 Then cur_an.duration = 30000
					EndIf
				EndIf
				
				'ANIM SEGMENT
				If my > 90 And my < 100
					If mx < 690 
						anim_index =  anim_index - 1
						If anim_index < 0 Then anim_index = cMAXANIMS-1
					Else
						anim_index =  anim_index + 1
						If anim_index > cMAXANIMS-1 Then anim_index = 0
					EndIf
					cur_an = anim_array[anim_index]
					SetGlobalValues()
				EndIf

				'START SHOW
				If my > 110 And my < 120
					cur_an.startOn = 1-cur_an.startOn 
				EndIf

				'END SHOW
				If my > 130 And my < 140
					cur_an.EndOn = 1-cur_an.EndOn 
				EndIf

				'concurrent/follows
				If my > 150 And my < 150+10
					cur_an.followprevious = 1-cur_an.followprevious
				EndIf

				'COPY
				If my > 170 And my < 170+10
					CopyToBuffer()
				EndIf

				'PASTE
				If my > 190 And my < 190+10
					PasteFromBuffer()
				EndIf

				'REVERSE
				If my > 210 And my < 210+10
					ReverseToFrom()
				EndIf

				'COPY SEGMENT
				If my > 230 And my < 230+10
					CopyToBuffer()
				EndIf

				'PASTE SEGMENT
				If my > 250 And my < 250+10
					PasteAllFromBuffer()
				EndIf

				'LOAD SEGMENT
				If my > 310 And my < 310+10
					LoadSegment(anim_index)
				EndIf

				'SAVE SEGMENT
				If my > 330 And my < 330+10
					SaveSegment(anim_index)
				EndIf

				'LOAD SET
				If my > 350 And my < 350+10
					LoadAllSegments()
				EndIf

				'SAVE SET
				If my > 370 And my < 370+10
					SaveAllSegments()
				EndIf
			EndIf
		EndIf
	EndIf 

	If MouseDown(1)
		Local mx = MouseX()
		Local my = MouseY()

		If mx < 400
			cur_an.set_position( MouseX(), MouseY(), se)
		Else
			'menu stuff
			If mx > 650
				'COLOUR BARS
				If my >= col_start_y+20-5 And my <= col_start_y+20+255+5
					If mx > col_start_x-5 And mx < col_start_x+10+5
						g_cl_r = my-col_start_y-20
						If g_cl_r < 0 Then g_cl_r = 0
						If g_cl_r > 255 Then g_cl_r = 255
						cur_an.set_r(g_cl_r,1)
					EndIf
					If mx > col_start_x+20-5 And mx < col_start_x+30+5 
						g_cl_g = my-col_start_y-20
						If g_cl_g < 0 Then g_cl_g = 0
						If g_cl_g > 255 Then g_cl_g = 255
						cur_an.set_g(g_cl_g,1)						
					EndIf
					If mx > col_start_x+40-5 And mx < col_start_x+50+5 
						g_cl_b = my-col_start_y-20
						If g_cl_b < 0 Then g_cl_b = 0
						If g_cl_b > 255 Then g_cl_b = 255
						cur_an.set_b(g_cl_b,1)						
					EndIf
					If mx > col_end_x-5 And mx < col_end_x+10+5
						g_cl_r = my-col_start_y-20
						If g_cl_r < 0 Then g_cl_r = 0
						If g_cl_r > 255 Then g_cl_r = 255
						cur_an.set_r(g_cl_r,0)
					EndIf
					If mx > col_end_x+20-5 And mx < col_end_x+30+5 
						g_cl_g = my-col_start_y-20
						If g_cl_g < 0 Then g_cl_g = 0
						If g_cl_g > 255 Then g_cl_g = 255
						cur_an.set_g(g_cl_g,0)						
					EndIf
					If mx > col_end_x+40-5 And mx < col_end_x+50+5 
						g_cl_b = my-col_start_y-20
						If g_cl_b < 0 Then g_cl_b = 0
						If g_cl_b > 255 Then g_cl_b = 255
						cur_an.set_b(g_cl_b,0)						
					EndIf
				EndIf
			EndIf
		EndIf
	EndIf 
	
	SetBlend alphablend

	SetColor 255,255,255
	DrawLine 50,50,350,50
	DrawLine 50,50,50,750
	DrawLine 50,750,350,750
	DrawLine 350,50,350,750

	SetColor 32,32,32
	DrawRect 402,0,400,800

	SetColor 200,200,200
	DrawRect 401,0,1,800

	If mouseover(650,10)
		ShowContext("Toggle animation segment ON/OFF")
		SetColor 250,250,250 
	Else 
		SetColor 180,180,180
	EndIf
	If cur_an.active = 0
		DrawText "SEGMENT OFF", 650, 10
	Else	
		DrawText "SEGMENT ON", 650, 10
	EndIf

	If mouseover(650,30)
		ShowContext("Toggle START or FINISH of animation segment")
		SetColor 250,250,250 
	Else 
		SetColor 180,180,180
	EndIf
	If se = 1
		DrawText "START POSITION", 650, 30
	Else	
		DrawText "FINISH POSITION", 650, 30
	EndIf

	If mouseover(650,50)
		ShowContext("Adjust delay time (inactive during delay) for this segment")
		SetColor 250,250,250 
	Else 
		SetColor 180,180,180
	EndIf
	DrawText "[-]  DELAY  [+]", 650, 50

	If mouseover(650,70)
		ShowContext("Adjust ength of animation section (not including delay)")
		SetColor 250,250,250 
	Else 
		SetColor 180,180,180
	EndIf
	DrawText "[-]  TIME   [+]", 650, 70

	If mouseover(650,90)
		ShowContext("Select current animation segment")
		SetColor 250,250,250 
	Else 
		SetColor 180,180,180
	EndIf
	DrawText "[-] SEGMENT [+]", 650, 90

	If mouseover(650,110)
		ShowContext("Is shape visible before start (during delay time)?")
		SetColor 250,250,250 
	Else 
		SetColor 180,180,180
	EndIf
	If cur_an.startOn = 0
		DrawText "START HIDDEN", 650, 110
	Else	
		DrawText "START VISIBLE", 650, 110
	EndIf

	If mouseover(650,130)
		ShowContext("Is shape visible after animation?")
		SetColor 250,250,250 
	Else 
		SetColor 180,180,180
	EndIf
	If cur_an.EndOn = 0
		DrawText "FINISH HIDDEN", 650, 130
	Else	
		DrawText "FINISH VISIBLE", 650, 130
	EndIf
	
	If mouseover(650,150)
		ShowContext("Does this segment run concurrently or after previous segments?")
		SetColor 250,250,250 
	Else 
		SetColor 180,180,180
	EndIf
	If cur_an.followprevious = 1
		DrawText "FOLLOWS", 650, 150
	Else	
		DrawText "CONCURRENT", 650, 150
	EndIf
	
	If mouseover(650,170)
		ShowContext("Copy current segment end parameters (SHAPE, POS, ROT, SCALE, COLOR)")
		SetColor 250,250,250 
	Else 
		SetColor 180,180,180
	EndIf
	DrawText "COPY CURRENT", 650, 170

	If mouseover(650,190)
		ShowContext("Paste copied segment end parameters (SHAPE, POS, ROT, SCALE, COLOR)")
		SetColor 250,250,250 
	Else 
		SetColor 180,180,180
	EndIf
	If se = 1
		DrawText "PASTE (START)", 650, 190
	Else	
		DrawText "PASTE (FINISH)", 650, 190
	EndIf

	If mouseover(650,210)
		ShowContext("Reverse segment's START/FINISH parameters (POS, ROT, SCALE, COLOR)")
		SetColor 250,250,250 
	Else 
		SetColor 180,180,180
	EndIf
	DrawText "REVERSE SEGMENT", 650, 210

	If mouseover(650,230) 
		ShowContext("Copy complete animation segment (START and FINISH)")
		SetColor 250,250,250 
	Else 
		SetColor 180,180,180
	EndIf
	DrawText "COPY SEGMENT", 650, 230

	If mouseover(650,250)
		ShowContext("Paste complete animation segment (START and FINISH)")
		SetColor 250,250,250 
	Else 
		SetColor 180,180,180
	EndIf
	DrawText "PASTE SEGMENT", 650, 250

	If mouseover(650,310)
		ShowContext("Load (from file) complete animation segment (START and FINISH)")
		SetColor 250,250,250 
	Else 
		SetColor 180,180,180
	EndIf
	DrawText "LOAD SEGMENT", 650, 310

	If mouseover(650,330)
		ShowContext("Save (to file) complete animation segment (START and FINISH)")
		SetColor 250,250,250 
	Else 
		SetColor 180,180,180
	EndIf
	DrawText "SAVE SEGMENT", 650, 330

	If mouseover(650,350)
		ShowContext("Load (from file) complete set of segments")
		SetColor 250,250,250 
	Else 
		SetColor 180,180,180
	EndIf
	DrawText "LOAD SET", 650, 350

	If mouseover(650,370)
		ShowContext("Save (to file) complete set of segments")
		SetColor 250,250,250 
	Else 
		SetColor 180,180,180
	EndIf
	DrawText "SAVE SET", 650, 370

	SetColor 180,180,180
	Local blockstarty = 10
	DrawText "CURRENT", 480,blockstarty
	DrawText "cur x  "+cur_an.x,440,blockstarty+20
	DrawText "cur y  "+cur_an.y,440,blockstarty+30
	DrawText "cur r  "+cur_an.cl_r,440,blockstarty+40
	DrawText "cur g  "+cur_an.cl_g,440,blockstarty+50
	DrawText "cur b  "+cur_an.cl_b,440,blockstarty+60
	DrawText "cur rt "+cur_an.rot,440,blockstarty+70
	DrawText "cur sx "+cur_an.sc_x,440,blockstarty+80
	DrawText "cur sy "+cur_an.sc_y,440,blockstarty+90

	blockstarty = 120
	DrawText "START", 480,blockstarty
	DrawText "x  "+cur_an.start_x,440,blockstarty+20
	DrawText "y  "+cur_an.start_y,440,blockstarty+30
	DrawText "r  "+cur_an.start_cl_r,440,blockstarty+40
	DrawText "g  "+cur_an.start_cl_g,440,blockstarty+50
	DrawText "b  "+cur_an.start_cl_b,440,blockstarty+60
	DrawText "rt "+cur_an.start_rot,440,blockstarty+70
	DrawText "sx "+cur_an.start_sc_x,440,blockstarty+80
	DrawText "sy "+cur_an.start_sc_y,440,blockstarty+90

	blockstarty = 230
	DrawText "FINISH", 480,blockstarty
	DrawText "x  "+cur_an.end_x,440,blockstarty+20
	DrawText "y  "+cur_an.end_y,440,blockstarty+30
	DrawText "r  "+cur_an.end_cl_r,440,blockstarty+40
	DrawText "g  "+cur_an.end_cl_g,440,blockstarty+50
	DrawText "b  "+cur_an.end_cl_b,440,blockstarty+60
	DrawText "rt "+cur_an.end_rot,440,blockstarty+70
	DrawText "sx "+cur_an.end_sc_x,440,blockstarty+80
	DrawText "sy "+cur_an.end_sc_y,440,blockstarty+90

	blockstarty = 360
	DrawText "Animation Segment: "+anim_index,440,blockstarty
	DrawText "Shape  "+cur_an.image_number,440,blockstarty+20
	DrawText image_filename[cur_an.image_number],450,blockstarty+30
	DrawText "Delay ms:          "+cur_an.delaysteps*MS_PER_FRAME,440,blockstarty+50
	DrawText "Visible at Start:  "+cur_an.startOn,440,blockstarty+60
	DrawText "Visible at End:    "+cur_an.EndOn,440,blockstarty+70
	DrawText "Anim Duration ms:  "+cur_an.duration,440,blockstarty+80
	DrawText "Anim Steps:        "+Int(cur_an.duration/MS_PER_FRAME),440,blockstarty+90
	DrawText "Total Steps:       "+(Int(cur_an.duration/MS_PER_FRAME)+cur_an.delaysteps),440,blockstarty+100

	blockstarty = 520
	DrawText "    KEYS",440,blockstarty
	
	DrawText "T - Change Image",440,blockstarty+20
	DrawText "A - Adjust Rotation ",440,blockstarty+30
	DrawText "S - Adjust Scale X",440,blockstarty+40
	DrawText "X - Adjust Scale Y",440,blockstarty+50
	DrawText "C - Adjust Scale XY",440,blockstarty+60
	DrawText "  +SHIFT for Negative",440,blockstarty+70
	DrawText "  +CTRL  for  x10",440,blockstarty+80

	DrawText "I - FLASH START/FINISH",440,blockstarty+100
	DrawText "U - PLAY SEGMENT",440,blockstarty+110
	DrawText "P - PLAY SET",440,blockstarty+120
	DrawText "P+SHIFT - SAVE SCRIPT",440,blockstarty+130
	DrawText "ESC - QUIT",440,blockstarty+160

	'colour graphs
	DrawText " START", col_start_x, col_start_y
	DrawText "  END", col_end_x, col_start_y
	For Local t:Int = 0 To 255
		SetColor t,0,0
		DrawRect col_start_x,col_start_y+20+t,10,1
		SetColor 0,t,0
		DrawRect col_start_x+20,col_start_y+20+t,10,1
		SetColor 0,0,t
		DrawRect col_start_x+40,col_start_y+20+t,10,1
	Next
	SetColor 128,128,128
	DrawRect col_start_x,col_start_y+20+cur_an.start_cl_r,10,1
	DrawRect col_start_x+20,col_start_y+20+cur_an.start_cl_g,10,1
	DrawRect col_start_x+40,col_start_y+20+cur_an.start_cl_b,10,1
	SetColor cur_an.start_cl_r,cur_an.start_cl_g,cur_an.start_cl_b
	DrawRect col_start_x,col_start_y+285,50,10

	For Local t:Int = 0 To 255
		SetColor t,0,0
		DrawRect col_end_x,col_start_y+20+t,10,1
		SetColor 0,t,0
		DrawRect col_end_x+20,col_start_y+20+t,10,1
		SetColor 0,0,t
		DrawRect col_end_x+40,col_start_y+20+t,10,1
	Next
	SetColor 128,128,128
	DrawRect col_end_x,col_start_y+20+cur_an.end_cl_r,10,1
	DrawRect col_end_x+20,col_start_y+20+cur_an.end_cl_g,10,1
	DrawRect col_end_x+40,col_start_y+20+cur_an.end_cl_b,10,1
	SetColor cur_an.end_cl_r,cur_an.end_cl_g,cur_an.end_cl_b
	DrawRect col_end_x,col_start_y+285,50,10

	If KeyHit(KEY_P)
		If KeyDown(KEY_LSHIFT)
			g_write_to_file = 1
			openOutputFile()
		EndIf
		write_a_line("# show_version=4")
		write_a_line("- time: 0")
		animate = 1
		start_animation()
		first_step = 1
	EndIf	

	If KeyHit(KEY_U)
		animate_current = 1
		start_animation()
	EndIf	
	
	If animate = 1
		update_shapes()
		If animate = 0
			Cls
		Else
			draw_Shapes()		
		EndIf
		led.updatecolors()
		led.dumpstate(1)
		first_step = 0
	Else
		If animate_current = 1
			update_Current_shape()
			If animate_current = 0
				'Cls
			Else
				draw_Shapes()		
			EndIf
			led.updatecolors()
		Else	
			draw_Shapes()	
		EndIf
	EndIf	
		
	led.DrawLeds()
	
	If KeyHit(KEY_SPACE)
		led.updatecolors()
		led.dumpstate(1)
	EndIf

  Flip

Until KeyHit(KEY_ESCAPE)

End 

'-----------------------------------------------------------------------------------------------------





Function ShowContext(txt$)

	SetColor 80,80,80
	DrawRect 20,750,610,40	
	SetColor 240,240,240
	
	DrawText txt, 30,760
	
End Function



Function mouseover:Int(x:Int,y:Int)

	Local my:Int, mx:Int
	my = MouseY()  
	mx = MouseX()
	If mx > x And my > y And my < y+10
		Return 1
	Else
		Return 0
	EndIf

End Function



Function SetGlobalValues()

	If se = 1
		g_cl_r = cur_an.start_cl_r
		g_cl_g = cur_an.start_cl_g
		g_cl_b = cur_an.start_cl_b
		g_sc_x = cur_an.start_sc_x
		g_sc_y = cur_an.start_sc_y
		g_rot = cur_an.start_rot
	Else
		g_cl_r = cur_an.end_cl_r
		g_cl_g = cur_an.end_cl_g
		g_cl_b = cur_an.end_cl_b
		g_sc_x = cur_an.end_sc_x
		g_sc_y = cur_an.end_sc_y
		g_rot = cur_an.end_rot
	EndIf

End Function



Type animation
	Field anim_number:Int 
	Field image_number:Int
	Field active:Int
	Field delaysteps:Int
	Field startOn:Int
	Field EndOn:Int 
	Field followprevious:Int
	Field duration:Int 
	
	Field total_steps:Int
	Field current_step:Int
	Field delay_count:Int
	
	Field rot:Float
	Field sc_x:Float
	Field sc_y:Float
	Field x:Float
	Field y:Float
	Field cl_r:Float
 	Field cl_g:Float
 	Field cl_b:Float

	Field start_rot:Float
	Field start_sc_x:Float
	Field start_sc_y:Float
	Field start_x:Float
	Field start_y:Float
	Field start_cl_r:Float
	Field start_cl_g:Float
	Field start_cl_b:Float

	Field end_rot:Float
	Field end_sc_x:Float
	Field end_sc_y:Float
	Field end_x:Float
	Field end_y:Float
	Field end_cl_r:Float
	Field end_cl_g:Float
	Field end_cl_b:Float

	Field delta_rot:Float
	Field delta_sc_x:Float
	Field delta_sc_y:Float
	Field delta_x:Float
	Field delta_y:Float
	Field delta_cl_r:Float
	Field delta_cl_g:Float
	Field delta_cl_b:Float
	Field animating:Int
	
	Function createAnimations()
		Local t:Int
		For t = 0 To cMAXANIMS-1
			anim_array[t] = New animation
			anim_array[t].anim_number = t
			anim_array[t].set_r(g_cl_r,1)
			anim_array[t].set_g(g_cl_g,1)
			anim_array[t].set_b(g_cl_b,1)
			anim_array[t].set_scale_x(g_sc_x,1)
			anim_array[t].set_scale_y(g_sc_y,1)
			anim_array[t].set_rotation(g_rot,1)
			anim_array[t].set_r(g_cl_r,0)
			anim_array[t].set_g(g_cl_g,0)
			anim_array[t].set_b(g_cl_b,0)
			anim_array[t].set_scale_x(g_sc_x,0)
			anim_array[t].set_scale_y(g_sc_y,0)
			anim_array[t].set_rotation(g_rot,0)
			anim_array[t].x = 50+150
			anim_array[t].y = 50+300
			anim_array[t].start_x = 50+150
			anim_array[t].start_y = 50+300
			anim_array[t].end_x = 50+150
			anim_array[t].end_y = 50+300
			anim_array[t].startOn = 0
			anim_array[t].endOn = 0
			anim_array[t].followprevious = 0
			anim_array[t].delaysteps = 0
			anim_array[t].duration = cDURATION
			anim_array[t].active = 0
			anim_array[t].animating = 0
		Next
	End Function


	Method set_delta() 
		delay_count = delaysteps
		current_step = 0
		total_steps = duration/MS_PER_FRAME ' 33 = 30 fps, 16 = 60
		delta_rot = (end_rot-start_rot)/total_steps
		delta_sc_x = (end_sc_x-start_sc_x)/total_steps
		delta_sc_y = (end_sc_y-start_sc_y)/total_steps
		delta_x = (end_x-start_x)/total_steps
		delta_y = (end_y-start_y)/total_steps
		delta_cl_r = (end_cl_r-start_cl_r)/total_steps
		delta_cl_g = (end_cl_g-start_cl_g)/total_steps
		delta_cl_b = (end_cl_b-start_cl_b)/total_steps
		animating = 1
	End Method

	Method set_cur_to_start() 
		rot = start_rot
		sc_x = start_sc_x
		sc_y = start_sc_y
		x = start_x
		y = start_y
		cl_r = start_cl_r
		cl_g = start_cl_g
		cl_b = start_cl_b
	End Method
	
	Method 	set_cur_to_end() 
		rot = end_rot
		sc_x = end_sc_x
		sc_y = end_sc_y
		x = end_x
		y = end_y
		cl_r = end_cl_r
		cl_g = end_cl_g
		cl_b = end_cl_b
	End Method
	
	Method cycle_image()
		image_number = (image_number + 1) Mod num_images
	End Method
	
	Method set_position(px:Int, py:Int, se:Int)
		If se = 1
			start_x = px
			start_y = py
		Else
			end_x = px
			end_y = py
		EndIf
		x = px
		y = py
	End Method

	Method set_scale_x(sc:Float, se:Int)
		If se = 1
			start_sc_x = sc
		Else
			end_sc_x = sc
		EndIf
		sc_x = sc
	End Method

	Method set_scale_y(sc:Float, se:Int)
		If se = 1
			start_sc_y = sc
		Else
			end_sc_y = sc
		EndIf
		sc_y = sc
	End Method

	Method set_rotation(rt:Float, se:Int)
		If se = 1
			start_rot = rt
		Else
			end_rot = rt
		EndIf
		rot = rt
	End Method
	
	Method set_r(c:Int, se:Int)
		If se = 1
			start_cl_r = c
		Else
			end_cl_r = c
		EndIf
		cl_r = c
	End Method

	Method set_g(c:Int, se:Int)
		If se = 1
			start_cl_g = c
		Else
			end_cl_g = c
		EndIf
		cl_g = c
	End Method

	Method set_b(c:Int, se:Int)
		If se = 1
			start_cl_b = c
		Else
			end_cl_b = c
		EndIf
		cl_b = c
	End Method
	
	Function ispreviouscomplete:Int(cur)
		Local complete:Int = 1
		'skip over segment 0 - it has no previous
		If cur > 0
			For Local t:Int = 0 To cur-1
				If anim_array[t].active = 1
					If anim_array[t].animating = 1
						complete = 0
					EndIf
				EndIf
			Next
		EndIf
		If animate_current = 1 Then complete = 1
		Return complete
	End Function

	Method update()
		If followprevious = 0 Or ispreviouscomplete(anim_number)
			delay_count = delay_count - 1
			If delay_count <= 0 
				delay_count = 0
				current_step =  current_step + 1
				If current_step <= total_steps
					update_scale()
					update_rotation()
					update_color()
					update_location()
				Else
					animating = 0
				EndIf
			EndIf
		EndIf
	End Method
	
	Method isShowing:Int()		
		Local show:Int = 0
		If animate = 0
			'show the current shape
			If Self = cur_an
				show = 1
			EndIf
		Else
			'running animation
			If delay_count > 0
				'waiting to move, show/hide?
				If startOn = 1
					If followprevious = 0 Or ispreviouscomplete(anim_number)
						show = 1
					EndIf
				EndIf
			Else
				'in animation 
				If animating = 1
					If followprevious = 0 Or ispreviouscomplete(anim_number)
						show = 1
					EndIf
				Else
					'after animation, show/hide?
					If endOn = 1
						show = 1
					EndIf
				EndIf
			EndIf
		EndIf
		Return show
	End Method

	Method update_scale()
		sc_x = sc_x + delta_sc_x
		sc_y = sc_y + delta_sc_y
	End Method

	Method update_rotation()
		rot = (rot + delta_rot) Mod 360
	End Method 

	Method update_color()
		cl_r = (cl_r + delta_cl_r) Mod 256
		cl_g = (cl_g + delta_cl_g) Mod 256
		cl_b = (cl_b + delta_cl_b) Mod 256
	End Method 

	Method update_location()
		x = x + delta_x
		y = y + delta_y
	End Method 

	Method draw()	
		Local which_se = se
		Local which_x = x
		Local which_y = y
		If flash > 0
			flash = flash - 1
			If flash Mod 30 < 15
				which_se = 0
				which_x = end_x
				which_y = end_y
			Else
				which_se = 1
				which_x = start_x
				which_y = start_y
			EndIf
		EndIf
		If isShowing()
			If animate = 1 Or animate_current = 1
				SetColor cl_r,cl_g,cl_b
				SetScale sc_x,sc_y
				SetRotation rot
			Else
				If which_se = 1
					which_x = start_x
					which_y = start_y
					SetColor start_cl_r,start_cl_g,start_cl_b
					SetScale start_sc_x,start_sc_y
					SetRotation start_rot
				Else
					which_x = end_x
					which_y = end_y
					SetColor end_cl_r,end_cl_g,end_cl_b
					SetScale end_sc_x,end_sc_y
					SetRotation end_rot
				EndIf
			EndIf
			If images[image_number] <> Null
				DrawImage images[image_number], which_x, which_y
			EndIf
		EndIf
	End Method 
	
	Method saveSegmentToFile(fh:TStream)
		If fh <> Null
			WriteLine(fh, "anim_number: "+anim_number)

			WriteLine(fh, "image_name: "+image_filename[image_number])
			
			WriteLine(fh, "active: "+active)
			WriteLine(fh, "delaysteps: "+delaysteps)
			WriteLine(fh, "startOn: "+startOn)
			WriteLine(fh, "EndOn: "+ EndOn)
			WriteLine(fh, "followprevious: "+followprevious)
			WriteLine(fh, "duration: "+ duration)
			
			WriteLine(fh, "rot: "+rot)
			WriteLine(fh, "sc_x: "+sc_x)
			WriteLine(fh, "sc_y: "+sc_y)
			WriteLine(fh, "x: "+x)
			WriteLine(fh, "y: "+y)
			WriteLine(fh, "cl_r: "+cl_r)
		 	WriteLine(fh, "cl_g: "+cl_g)
		 	WriteLine(fh, "cl_b: "+cl_b)
		
			WriteLine(fh, "start_rot: "+start_rot)
			WriteLine(fh, "start_sc_x: "+start_sc_x)
			WriteLine(fh, "start_sc_y: "+start_sc_y)
			WriteLine(fh, "start_x: "+start_x)
			WriteLine(fh, "start_y: "+start_y)
			WriteLine(fh, "start_cl_r: "+start_cl_r)
			WriteLine(fh, "start_cl_g: "+start_cl_g)
			WriteLine(fh, "start_cl_b: "+start_cl_b)
		
			WriteLine(fh, "end_rot: "+end_rot)
			WriteLine(fh, "end_sc_x: "+end_sc_x)
			WriteLine(fh, "end_sc_y: "+end_sc_y)
			WriteLine(fh, "end_x: "+end_x)
			WriteLine(fh, "end_y: "+end_y)
			WriteLine(fh, "end_cl_r: "+end_cl_r)
			WriteLine(fh, "end_cl_g: "+end_cl_g)
			WriteLine(fh, "end_cl_b: "+end_cl_b)
		EndIf
	End Method
	
	Method loadSegmentFromFile(fh:TStream, a:animation)
		Local line$
		Local param$, val$
		Try
			'segment number
			line$ = ReadLine(fh)
			param$ = ParseString$(line$,1,":")
			Local anim_num_from_file = Int(ParseString$(line$,2,":"))
			
			'image file name
			line$ = ReadLine(fh); param$ = ParseString$(line$,1,":")
			Local image_name_from_file$ = Trim(ParseString$(line$,2,":"))
			Local shape_image_index = getShapeIndex(image_name_from_file)
			If shape_image_index = -1
				Throw "Can't find shape image referenced in segment file: "+image_name_from_file 
			EndIf
			a.image_number = shape_image_index 
			
			line$ = ReadLine(fh)'; param$ = ParseString$(line$,1,":")
			a.active = Int(ParseString$(line$,2,":"))
			
			line$ = ReadLine(fh)'; param$ = ParseString$(line$,1,":")
			a.delaysteps = Int(ParseString$(line$,2,":"))
			
			line$ = ReadLine(fh)' param$ = ParseString$(line$,1,":")
			a.startOn = Int(ParseString$(line$,2,":"))
			
			line$ = ReadLine(fh)' param$ = ParseString$(line$,1,":");val = Int(ParseString$(line$,2,":"))
			a.EndOn = Int(ParseString$(line$,2,":"))

			line$ = ReadLine(fh)' param$ = ParseString$(line$,1,":");val = Int(ParseString$(line$,2,":"))
			a.followprevious = Int(ParseString$(line$,2,":"))
			
			line$ = ReadLine(fh)' param$ = ParseString$(line$,1,":");val = Int(ParseString$(line$,2,":"))
			a.duration = Int(ParseString$(line$,2,":"))
				
			line$ = ReadLine(fh)' param$ = ParseString$(line$,1,":");val = Float(ParseString$(line$,2,":"))
			a.rot = Float(ParseString$(line$,2,":"))

			line$ = ReadLine(fh)' param$ = ParseString$(line$,1,":");val = Float(ParseString$(line$,2,":"))
			a.sc_x = Float(ParseString$(line$,2,":"))

			line$ = ReadLine(fh)' param$ = ParseString$(line$,1,":");val = Float(ParseString$(line$,2,":"))
			a.sc_y = Float(ParseString$(line$,2,":"))
			
			line$ = ReadLine(fh)' param$ = ParseString$(line$,1,":");val = Float(ParseString$(line$,2,":"))
			a.x = Float(ParseString$(line$,2,":"))

			line$ = ReadLine(fh)' param$ = ParseString$(line$,1,":");val = Float(ParseString$(line$,2,":"))			
			a.y = Float(ParseString$(line$,2,":"))
			
			line$ = ReadLine(fh)' param$ = ParseString$(line$,1,":");val = Float(ParseString$(line$,2,":"))			
			a.cl_r = Float(ParseString$(line$,2,":"))
			
			line$ = ReadLine(fh)' param$ = ParseString$(line$,1,":");val = Float(ParseString$(line$,2,":"))			
		 	a.cl_g = Float(ParseString$(line$,2,":"))

			line$ = ReadLine(fh)' param$ = ParseString$(line$,1,":");val = Float(ParseString$(line$,2,":"))		
		 	a.cl_b = Float(ParseString$(line$,2,":"))
	
			line$ = ReadLine(fh)' param$ = ParseString$(line$,1,":");val = Float(ParseString$(line$,2,":"))	
			a.start_rot = Float(ParseString$(line$,2,":"))
			
			line$ = ReadLine(fh)' param$ = ParseString$(line$,1,":");val = Float(ParseString$(line$,2,":"))			
			a.start_sc_x = Float(ParseString$(line$,2,":"))

			line$ = ReadLine(fh)' param$ = ParseString$(line$,1,":");val = Float(ParseString$(line$,2,":"))			
			a.start_sc_y = Float(ParseString$(line$,2,":"))

			line$ = ReadLine(fh)' param$ = ParseString$(line$,1,":");val = Float(ParseString$(line$,2,":"))			
			a.start_x = Float(ParseString$(line$,2,":"))

			line$ = ReadLine(fh)' param$ = ParseString$(line$,1,":");val = Float(ParseString$(line$,2,":"))			
			a.start_y = Float(ParseString$(line$,2,":"))

			line$ = ReadLine(fh)' param$ = ParseString$(line$,1,":");val = Float(ParseString$(line$,2,":"))			
			a.start_cl_r = Float(ParseString$(line$,2,":"))
			
			line$ = ReadLine(fh)' param$ = ParseString$(line$,1,":");val = Float(ParseString$(line$,2,":"))			
			a.start_cl_g = Float(ParseString$(line$,2,":"))

			line$ = ReadLine(fh)' param$ = ParseString$(line$,1,":");val = Float(ParseString$(line$,2,":"))			
			a.start_cl_b = Float(ParseString$(line$,2,":"))
		
			line$ = ReadLine(fh)' param$ = ParseString$(line$,1,":");val = Float(ParseString$(line$,2,":"))		
			a.end_rot = Float(ParseString$(line$,2,":"))
			
			line$ = ReadLine(fh)' param$ = ParseString$(line$,1,":");val = Float(ParseString$(line$,2,":"))			
			a.end_sc_x = Float(ParseString$(line$,2,":"))
			
			line$ = ReadLine(fh)' param$ = ParseString$(line$,1,":");val = Float(ParseString$(line$,2,":"))			
			a.end_sc_y = Float(ParseString$(line$,2,":"))
			
			line$ = ReadLine(fh)' param$ = ParseString$(line$,1,":");val = Float(ParseString$(line$,2,":"))			
			a.end_x = Float(ParseString$(line$,2,":"))
			
			line$ = ReadLine(fh)' param$ = ParseString$(line$,1,":");val = Float(ParseString$(line$,2,":"))			
			a.end_y = Float(ParseString$(line$,2,":"))
			
			line$ = ReadLine(fh)' param$ = ParseString$(line$,1,":");val = Float(ParseString$(line$,2,":"))			
			a.end_cl_r = Float(ParseString$(line$,2,":"))
			
			line$ = ReadLine(fh)' param$ = ParseString$(line$,1,":");val = Float(ParseString$(line$,2,":"))			
			a.end_cl_g = Float(ParseString$(line$,2,":"))
			
			line$ = ReadLine(fh)' param$ = ParseString$(line$,1,":");val = Float(ParseString$(line$,2,":"))			
			a.end_cl_b = Float(ParseString$(line$,2,":"))
		Catch err$
			DebugLog("Error reading File."+err$)	
		EndTry
		
	End Method

End Type





Function ReverseToFrom()

	'copy start
	Local lcl_r:Float = cur_an.start_cl_r
	Local lcl_g:Float = cur_an.start_cl_g
	Local lcl_b:Float = cur_an.start_cl_b
	Local lsc_x:Float = cur_an.start_sc_x
	Local lsc_y:Float = cur_an.start_sc_y
	Local lrot:Float = cur_an.start_rot
	Local lx:Float = cur_an.start_x
	Local ly:Float = cur_an.start_y

	'copy end to start
	cur_an.set_r(cur_an.end_cl_r,1)
	cur_an.set_g(cur_an.end_cl_g,1)
	cur_an.set_b(cur_an.end_cl_b,1)
	cur_an.set_scale_x(cur_an.end_sc_x,1)
	cur_an.set_scale_y(cur_an.end_sc_y,1)
	cur_an.set_rotation(cur_an.end_rot,1)
	cur_an.set_position(cur_an.end_x,cur_an.end_y,1)
	
	'copy start to end
	cur_an.set_r(lcl_r,0)
	cur_an.set_g(lcl_g,0)
	cur_an.set_b(lcl_b,0)
	cur_an.set_scale_x(lsc_x,0)
	cur_an.set_scale_y(lsc_y,0)
	cur_an.set_rotation(lrot,0)
	cur_an.set_position(lx,ly,0)
	
End Function



Function CopyToBuffer()

	'copy from current
	bufferAnim.cl_r = cur_an.cl_r
	bufferAnim.cl_g = cur_an.cl_g
	bufferAnim.cl_b = cur_an.cl_b
	bufferAnim.sc_x = cur_an.sc_x
	bufferAnim.sc_y = cur_an.sc_y
	bufferAnim.rot = cur_an.rot
	bufferAnim.x = cur_an.x
	bufferAnim.y = cur_an.y

	bufferAnim.start_cl_r = cur_an.start_cl_r
	bufferAnim.start_cl_g = cur_an.start_cl_g
	bufferAnim.start_cl_b = cur_an.start_cl_b
	bufferAnim.start_sc_x = cur_an.start_sc_x
	bufferAnim.start_sc_y = cur_an.start_sc_y
	bufferAnim.start_rot = cur_an.start_rot
	bufferAnim.start_x = cur_an.start_x
	bufferAnim.start_y = cur_an.start_y

	bufferAnim.end_cl_r = cur_an.end_cl_r
	bufferAnim.end_cl_g = cur_an.end_cl_g
	bufferAnim.end_cl_b = cur_an.end_cl_b
	bufferAnim.end_sc_x = cur_an.end_sc_x
	bufferAnim.end_sc_y = cur_an.end_sc_y
	bufferAnim.end_rot = cur_an.end_rot
	bufferAnim.end_x = cur_an.end_x
	bufferAnim.end_y = cur_an.end_y
	
	bufferAnim.image_number = cur_an.image_number
	bufferAnim.active = cur_an.active
	bufferAnim.delaysteps = cur_an.delaysteps
	bufferAnim.startOn = cur_an.startOn
	bufferAnim.EndOn = cur_an.EndOn
	bufferAnim.duration = cur_an.duration
	bufferAnim.followprevious = cur_an.followprevious
	
End Function



Function PasteFromBuffer()
	cur_an.set_r(bufferAnim.cl_r,se)
	cur_an.set_g(bufferAnim.cl_g,se)
	cur_an.set_b(bufferAnim.cl_b,se)
	cur_an.set_scale_x(bufferAnim.sc_x,se)
	cur_an.set_scale_y(bufferAnim.sc_y,se)
	cur_an.set_rotation(bufferAnim.rot,se)
	cur_an.set_position(bufferAnim.x,bufferAnim.y,se)
End Function



Function PasteAllFromBuffer()

	cur_an.cl_r = bufferAnim.cl_r
	cur_an.cl_g = bufferAnim.cl_g
	cur_an.cl_b = bufferAnim.cl_b
	cur_an.sc_x = bufferAnim.sc_x
	cur_an.sc_y = bufferAnim.sc_y
	cur_an.rot = bufferAnim.rot
	cur_an.x = bufferAnim.x
	cur_an.y = bufferAnim.y

	cur_an.start_cl_r = bufferAnim.start_cl_r
	cur_an.start_cl_g = bufferAnim.start_cl_g
	cur_an.start_cl_b = bufferAnim.start_cl_b
	cur_an.start_sc_x = bufferAnim.start_sc_x
	cur_an.start_sc_y = bufferAnim.start_sc_y
	cur_an.start_rot = bufferAnim.start_rot
	cur_an.start_x = bufferAnim.start_x
	cur_an.start_y = bufferAnim.start_y

	cur_an.end_cl_r = bufferAnim.end_cl_r
	cur_an.end_cl_g = bufferAnim.end_cl_g
	cur_an.end_cl_b = bufferAnim.end_cl_b
	cur_an.end_sc_x = bufferAnim.end_sc_x
	cur_an.end_sc_y = bufferAnim.end_sc_y
	cur_an.end_rot = bufferAnim.end_rot
	cur_an.end_x = bufferAnim.end_x
	cur_an.end_y = bufferAnim.end_y
	
	cur_an.image_number = bufferAnim.image_number
	cur_an.active = bufferAnim.active
	cur_an.delaysteps = bufferAnim.delaysteps
	cur_an.startOn = bufferAnim.startOn
	cur_an.EndOn = bufferAnim.EndOn
	cur_an.duration = bufferAnim.duration
	cur_an.followprevious = bufferAnim.followprevious

	cur_an.set_r(bufferAnim.cl_r,se)
	cur_an.set_g(bufferAnim.cl_g,se)
	cur_an.set_b(bufferAnim.cl_b,se)
	cur_an.set_scale_x(bufferAnim.sc_x,se)
	cur_an.set_scale_y(bufferAnim.sc_y,se)
	cur_an.set_rotation(bufferAnim.rot,se)
	cur_an.set_position(bufferAnim.x,bufferAnim.y,se)

End Function



Function loadImages()

	num_images = 0
	AutoImageFlags (FILTEREDIMAGE|MIPMAPPEDIMAGE)
	AutoMidHandle(True) 
	
	Local fh:TStream
	Local s,b,t
	Local pm$
	Local parts$[]
	Local fn$
	Local ftype = 0
	Local dir$ = "shapes"
	Local subdir$ = ""
	Local hdir
	
	s = 0
	hdir = ReadDir(dir$)
	If hdir <> 0
		subdir$ = NextFile(hdir)
		While subdir$ <> ""
			ftype = FileType(dir$+"\"+subdir$)
			fn$ = dir$+"\"+subdir$
			If subdir$ = "." Or subdir$ = ".." Or ftype = 2 ' sub directory
				fn$ = ""
			Else
				If fn$ <> ""
					If s < cMAXIMAGES
						image_filename$[s] = subdir$
						images[s] = LoadImage(fn$)
					EndIf
					s:+1
				EndIf 
			EndIf
			subdir$ = NextFile(hdir)
		Wend
		CloseDir hdir
	EndIf

	num_images = s

End Function



Function getShapeIndex:Int(image_name$)

	Local ret = -1
	Local t = 0
	While t < cMAXIMAGES
		Local img$ = image_filename$[t]
		If image_name = img
			ret = t
			t = 100000
		EndIf
		t= t + 1
	Wend
	Return ret

End Function



Function start_animation()

	Local t:Int
	For t = 0 To cMAXANIMS-1
		If anim_array[t].active = 1
			anim_array[t].set_delta()
			anim_array[t].set_cur_to_start()
		EndIf
	Next	
	
End Function



Function draw_Shapes()

	SetBlend lightblend
	Local t:Int
	For t = 0 To cMAXANIMS-1
		If anim_array[t].active = 1
			anim_array[t].draw()
		EndIf
	Next	
	
End Function



Function update_Current_shape()

	If anim_array[anim_index].active = 1
		anim_array[anim_index].update()
		If anim_array[anim_index].animating = 0 Then animate_current = 0
	Else
		animate_current = 0
	EndIf
	
End Function



Function update_shapes()

	Local t:Int
	Local animating:Int = 0
	For t = 0 To cMAXANIMS-1
		If anim_array[t].active = 1
			anim_array[t].update()
			If anim_array[t].animating = 1 Then animating = 1
		EndIf
	Next	
	If animating = 0
		animate = 0
		If g_write_to_file = 1
			CloseFile g_fh
			g_write_to_file = 0
		EndIf
	EndIf

End Function



Function GetPixel:appColor(x:Int, y:Int)

  ' should read the backbuffer at x, y and return a Type-variable containing r, g, b, a
  Local result:appColor =New appColor

  Local tmp:TImage =CreateImage(1, 1, DYNAMICIMAGE)
  GrabImage tmp, x, y
  Local temp:TPixmap =LockImage(tmp)
  Local argb:Int =Temp.ReadPixel(0, 0)
  UnlockImage(tmp)
  result.alpha =(argb Shr 24) & $ff
  result.red   =(argb Shr 16) & $ff
  result.green =(argb Shr 8) & $ff
  result.blue  =argb & $ff

  Return result

End Function



Function SetUpLeds()

	Local fh:TStream, fn$
	Local ln$
	Local ledname$
	Local xf:Float, yf:Float
	Local lnum% = 0
	
	fn$ = "ledsloc.txt"
	
	fh = OpenFile(fn$)
	If fh <> Null
		While Not Eof(fh)
			ln$ = ReadLine(fh)
			ledname$ = ParseString$(ln$, 1,":")
			ln$ = ReadLine(fh)
			xf = Float(ParseString$(ln$, 2,":"))
			ln$ = ReadLine(fh)
			yf = Float(ParseString$(ln$, 2,":"))
			'DebugLog(ledname$+Int(xf*400)+Int(yf*800))
			led.CreateLed(ledname, 50+Int(xf*300), 50+Int(yf*700))
		Wend
		CloseFile fh
	EndIf			
	
End Function

	
	
Function ParseString$(s$ , segment% , del$)

	If Right$(s$ , 1) <> del$
		s$ = s$ + del$
	EndIf
	Local stemp$ = ""
	Local numtemp% = 0
	For Local temp:Int = 1 To Len(s$)
		If Mid(s$, temp, 1) <> del$
			stemp$ = stemp$ + Mid(s$, temp, 1)
		Else
			numtemp = numtemp + 1
			If numtemp = segment
			  Return stemp$
			Else
			  stemp$ = ""
			EndIf
		EndIf
	Next
	
	Return ""

End Function
	
	

Type appColor

	Field red:Int
	Field green:Int
	Field blue:Int 
	Field alpha:Int
	
End Type
   
	
	
Type led

	Field name$, x#, y#
	Field r:Int, g:Int, b:Int
	Field prev_r:Int, prev_g:Int, prev_b:Int
	Field active:Int
	Field num_leds:Int

	Function CreateLed( name$, x#, y# )	
		Local t:Int = num_leds 
		ledarray[t] = New led
		ledarray[t].name = name
		ledarray[t].x = x
		ledarray[t].y = y
		ledarray[t].r = 0
		ledarray[t].g = 0
		ledarray[t].b = 0
		ledarray[t].active = 1
		ledarray[t].prev_r = 0
		ledarray[t].prev_g = 0
		ledarray[t].prev_b = 0
		num_leds = num_leds + 1
		'DebugLog "LED "+num_leds+" created"
	End Function	
	
	Function DrawLeds()
		Local p:led
		Local t:Int
		
		SetRotation 0
		SetScale 1,1
		SetAlpha 1
		SetLineWidth 1.0
		For t = 0 To num_leds-1
			p:led= ledarray[t]
			If p.active > 0
				SetColor 255,255,255
				DrawLine p.x-4,p.y-4,p.x+4,p.y-4
				DrawLine p.x-4,p.y-4,p.x-4,p.y+4
				DrawLine p.x+4,p.y-4,p.x+4,p.y+4
				DrawLine p.x-4,p.y+4,p.x+4,p.y+4
			EndIf
		Next	
					
	End Function
	
	Function UpdateColors()	
		Local p:led,t:Int
		For t = 0 To num_leds-1
			p:led = ledarray[t]
			If p.active > 0
				p.Update()
			EndIf
		Next	
	End Function

	Method Update()	
		prev_r = r
		prev_g = g
		prev_b = b				
		pixColor = GetPixel(x, y)
		r = pixColor.red
		g = pixColor.green
		b = pixColor.blue
	End Method
		
	Function dumpState(diff=0)	
		Local p:led, t:Int
		Local r$, g$, b$
		Local cnt:Int = 0
		For t = 0 To num_leds-1
			p:led = ledarray[t]
			If p.active > 0
				If diff = 0
					cnt=cnt+1
				Else
					If (p.prev_r <> p.r Or p.prev_g <> p.g Or p.prev_b <> p.b)					
						cnt=cnt+1
					EndIf
				EndIf
			EndIf
		Next	
		If cnt > 0
			If first_step = 0 Then write_a_line("- time: '+1'")
		  	write_a_line("  leds:")
			For t = 0 To num_leds-1
				p:led = ledarray[t]
				If p.active > 0
					If diff = 0
						r$ = Mid(Hex(p.r), 7, 2)
						g$ = Mid(Hex(p.g), 7, 2)
						b$ = Mid(Hex(p.b), 7, 2)
						write_a_line("    "+p.name+": '"+ r+g+b+"'")
					Else
						If (p.prev_r <> p.r Or p.prev_g <> p.g Or p.prev_b <> p.b)					
							r$ = Mid(Hex(p.r), 7, 2)
							g$ = Mid(Hex(p.g), 7, 2)
							b$ = Mid(Hex(p.b), 7, 2)
							write_a_line("    "+p.name+": '"+ r+g+b+"'")
						EndIf
					EndIf
				EndIf
			Next	
			write_a_line("    ")
		Else
			write_a_line("#No change this frame - take another step")
		  	write_a_line("#  leds:")
			write_a_line("- time: '+1'")
			write_a_line("    ")
		EndIf
	End Function
	
End Type
	

	
Function openOutputFile()

	Local fn$
	Local t:Int = 1
	While t < 10000
		fn$ = "output"+t+".yaml"
		If FileSize(fn$) = -1
			g_fh = WriteFile(fn$)
			t = 100000
		Else 
			t = t+1
		EndIf
	Wend

End Function



Function write_a_line(txt$)	

	If g_write_to_file = 1
		If g_fh <> Null
			WriteLine (g_fh,txt)
		EndIf
	Else
		DebugLog txt
	EndIf
	
End Function



Function SaveAllSegments()

	Local fh:TStream
	Local sfn$ = "Animation Set.txt"
	Local filter$ = "Set Files:txt;All Files:*"
	Local fn$ = RequestFile( "Save Set",filter$,True, CurrentDir()+"/sets/"+sfn$)
	
	fh = WriteFile(fn$)
	If fh <> Null
		Local t:Int
		For t = 0 To cMAXANIMS-1
			anim_array[t].SaveSegmentToFile(fh)
		Next	
		CloseFile(fh)
	Else
		DebugLog("Error Opening File: "+fn$)				
	EndIf	

End Function



Function LoadAllSegments()

	Local fh:TStream
	Local lfn$ = "Animation Set.txt"
	Local filter$ = "Set Files:txt;All Files:*"
	Local fn$ = RequestFile( "Load Set",filter$, False, CurrentDir()+"/sets/"+lfn$)
	
	fh = ReadFile(fn$)
	If fh <> Null
		Local t:Int
		For t = 0 To cMAXANIMS-1
			anim_array[t].LoadSegmentFromFile(fh, anim_array[t])
		Next	
		CloseFile(fh)	
	Else
		DebugLog("Error Opening File: "+fn$)				
	EndIf	

End Function



Function SaveSegment(bsegmentNum:Int)

	Local fh:TStream
	Local sfn$ = "segment_"+bsegmentNum+".txt"
	Local filter$ = "Segment Files:txt;All Files:*"
	Local fn$ = RequestFile( "Save Segment",filter$,True, CurrentDir()+"/segments/"+sfn$)
	
	fh = WriteFile(fn$)
	If fh <> Null
		cur_an.SaveSegmentToFile(fh)
		CloseFile(fh)
	Else
		DebugLog("Error Opening File: "+fn$)				
	EndIf	
	
End Function



Function LoadSegment(segmentNum:Int)

	Local fh:TStream
	Local lfn$ = "segment_"+segmentnum+".txt"
	Local filter$ = "Segment Files:txt;All Files:*"
	Local fn$ = RequestFile( "Load Segment",filter$, False, CurrentDir()+"/segments/"+lfn$)
	
	fh = ReadFile(fn$)
	If fh <> Null
		cur_an.LoadSegmentFromFile(fh,cur_an)
		CloseFile(fh)	
	Else
		DebugLog("Error Opening File: "+fn$)				
	EndIf	
	
End Function
	

	
	
