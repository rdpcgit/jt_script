; Script:  LOGOFF  for JT.
;
; Revision History
; ------------------
; INSTRUCTIONS:
;==============
; 1. Put this in STARTUP FOlder so it starts after logging in.
; 2. ALSO Use PARENTAL CONTROLS on Windows7 Control Panel / User Accounts
;	      to DISABLE LOGGING IN at RESTRICTED TIMES (Hours)...
;=================================================================================================================

#include <GUIConstants.au3>
#include <Date.au3>
#include <Array.au3>
#Include <File.au3>
#include <File.au3>
#include <FileConstants.au3>
#include <MsgBoxConstants.au3>
#include <WinAPIFiles.au3>
; ------------------------

; Initialize variables:
$testing = 1;
$label_text = ""
$program_to_stop = "";
$stopping = 0;
$username = @username;  ; login name

$obv_title = ""; startup menu title
$xsize=400;
$ysize=200;
$gui_menu = GUICreate($obv_title, $xsize, $ysize, -1,-1)  ; Window title, Width, Height, -1 is centered.
$version = "0"

; Hide Icon for this program so can't see it on the task bar for user to close.
Opt("TrayIconHide", 1)

; Read file containing times for login_start..$hour_break..$dinner_stop..etc
; ==========================================================================
   $file = "c:\Windows_misc\autoit_times.txt";
   FileOpen($file,0);
   If (Not FileExists($file)) Then
	  Msgbox(0, " ", "File does not exist.", 3);
	  exit;
   Endif
   $count = 1 + _FileCountLines($file)

; SAMPLE INPUT FILE - autoit_times.txt
#comments-start
; 1. line3: login_start
; 2. line4: login_end
09
21
; 5. line7: lunch_start
; 6. line8: lunch-stop
11
13
; 9.  line 10: hour_break
15
; 11. line 13: dinner_start
; 12. line 14: dinner_stop
18
20
; 15. line 16: hour_stop
21
#comments-end

   ; Read file Line by line:
   For $i = 1 to _FileCountLines($file)
	  $line = FileReadLine($file, $i);   ; tag: "Readfile"
	  if ($i == 3) Then
		 $login_start = $line;
	  elseif ($i == 4) Then
		 $login_end = $line;
	  elseif ($i == 7) Then
		 $lunch_start = $line;
	  elseif ($i == 8) Then
		 $lunch_stop = $line;
	  elseif ($i == 10) Then
		 $hour_break1 = $line;
   	  elseif ($i == 13) Then
		 $dinner_start = $line;
   	  elseif ($i == 14) Then
		 $dinner_stop = $line;
	  elseif ($i == 16) Then
		 $hour_stop = $line;
	  endif
   Next
   FileClose($file)

; Get initial Time parameters:
$hour = @HOUR
$minute = @MIN
$second = @SEC
; Login start hours < 12 must be 2 digits when comparing:
$login_start = $login_start + 0;
if ($login_start < 12) Then
    $login_start = "0" & $login_start;
 endif

; Display read values:
if ($testing == 1) then
   Msgbox(0,'',"Current Hour, login_start,end -- " & $hour & "," & $login_start & "," & $login_end, 3);
   Msgbox(0,'',"hour_stop  -- " & $hour_stop, 3);
endif

; GUI X, Y location
$x = 50;
$y = 20;
$xwidth = 200
$length = $xsize-100;
$x_input = $x + 70;
$ylabel = $y + 30

; START Timer
; ===========
; LOOP, until time to stop.

; Initialize variables:
$begin = TimerInit()
$wait_loop_seconds = 60;                   ; # seconds to Wait between Loops ("Delay")
$wait_loop_milliseconds = $wait_loop_seconds * 1000; ; # milliseconds to Wait between Loops
$stop_milliseconds = 30000;                ; # milliseconds before Stopping/Exiting.
$stop_seconds = $stop_milliseconds / 1000; ; # seconds

; Loop now
; .. and wait "wait_loop_milliseconds" between loops.

While 1

	; Get time difference (milliseconds) since last update
	$dif_wait = TimerDiff($begin)

	; Get latest Time parameters:
	$hour = @HOUR
	$minute = @MIN
	$second = @SEC

	; Test display of Message - display Time (disappears after 3 seconds)
	if ($testing == 1) then
	    $wait_loop_milliseconds = 7000;
		Msgbox(0, " ", "TESTING - Dif_wait and Time == " & $dif_wait & "," & $hour & ", " & $minute & "," & $second, 3);
	endif

	; TIME RESTRICTIONS:
	; for LOGIN start and Login end time
	; and LUNCH and DINNER start/stop
	; - do only for GAMES login username account
	;; if ( ($username == "games") _
	If ( ($hour < $login_start or $hour >= $login_end or $hour == $hour_break1) _
   		   or ($hour >= $lunch_start and $hour < $lunch_stop) _
           or ($hour >= $dinner_start and $hour < $dinner_end) _
           or ($hour >= $hour_stop)  ) Then

		 If ($hour >= $lunch_start and $hour < $lunch_stop)  Then
			Msgbox(0, " ", "... LUNCH TIME ...", 3);
		 elseif ($hour >= $dinner_start and $hour < $dinner_end) Then
			Msgbox(0, " ", "... DINNER TIME ...", 3);
		 elseif ($hour >= $login_end) Then
			   Msgbox(0, " ", "... It's almost Bed Time ...", 3);
		 Endif

		; Set LOG OFF flag
		 $stopping = 1

		; Stop right away if Before login:
		if ($dif_wait < $wait_loop_milliseconds)  Then
			if ($testing == 0) then
			   Msgbox(0, " ", "...LOGIN NOT ALLOWED at this time ... LOGGING OFF..", 3);
			   sleep(3000);  	; milliseconds delay
			   if  NOT ($username == "rdavid") then
				  shutdown(16);   ; 16 == Logoff
			   endif
			   exit;
			endif
		endif

	Else
		; OK here. NOT logging off.
		; .. KEEP LOOPING till TIME Restriction is found
		; .. until 11pm (23pm) or after, then Exit the script.
		$stopping = 0;
		if ($hour >= 23) Then
			Msgbox(0, " ", "... Exiting Script After 11pm ... ", 3);
			exit;
		 endif

	Endif

	; LOG OFF or End Game the predefined time & hour:
	; .. Display Warning before Exiting.
	; =================================================

	if ($stopping == 1 ) Then

		SoundPlay(@WindowsDir & "\media\tada.wav", 1);  ; play sound before displaying Log off.
		Msgbox(0, " ", "...LOGGING OFF SOON...in 1 MINUTE", 3);
		sleep(60000);  ; 60,000 ms, 1 minute

		WinMinimizeAll();  ; Minimize windows to alert user.

		GUISetState(@SW_SHOW)
		GuiCtrlCreateLabel("NOTE: LOGGING OFF SOON ... SAVE YOUR WORK NOW ... ", $x, $y+50,300, 40)
		GuiCtrlSetBkColor(-1, 0x00FF00)	 ; set label background color to green (0x00FF00) when done.
		sleep(5000);
	    WinMinimizeAllUndo()   ; Maximize windows to original state

		$x = $x_input - 70
		$y = $ylabel + 60;

		GUISetState(@SW_SHOW)
		GuiCtrlCreateLabel("EXITING in " & $stop_seconds & " seconds ...", $x, $y, 300, 40)
		GuiCtrlSetBkColor(-1, 0x00FF00)	 ; set label background color to green (0x00FF00) when done.
		sleep($stop_milliseconds)

		; LOGOFF / Shutdown computer if requested.
		if ( $stopping == 1 ) Then
			Msgbox(0, " ", "...LOGGING OFF NOW...", 3);
			if ($testing == 0) then
			   shutdown(16);  ; 16 == Logoff
			endif
			; To shutdown instead, use the following:
			;;shutdown(13);  ; Shutdown(1) and Power down(8), Force it (4). Total = 13;
			exit
		Endif
	Endif ; end_if_stopping

	; WAIT in between loops:
	sleep ($wait_loop_milliseconds);

Wend  ; End of while loop

; We're done here.

; ----------------------------------------------------------
