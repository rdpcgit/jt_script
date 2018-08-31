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
; 2. line4: login_stop
09
21
; 5. line7: lunch_start
; 6. line8: lunch_stop
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
; 17. line 18: (1)-Weekdays time restrictions
1
; 19. line 20: (1)-Friday/Weekend time restrictions
1
; 21. line 22: enable(1)/disable(0) time restrictions
1
#comments-end

   ; Read file Line by line:
   For $i = 1 to _FileCountLines($file)
	  $line = FileReadLine($file, $i);   ; tag: "Readfile"
	  if ($i == 3) Then
		 $login_start = $line;
	  elseif ($i == 4) Then
		 $login_stop = $line;
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
	  elseif ($i == 18) Then
		 $weekday_flag = $line;    ; weekday flag
	  elseif ($i == 20) Then
		 $weekend_flag = $line;    ; Fridays & Weekend flag
	  elseif ($i == 22) Then
		 $enable_flag = $line;
	  endif
   Next
   FileClose($file)

; SCRIPT Restriction (Enable/Disable)
; ====================================
; If ENABLE flag is not set,
; .. exit the script now. (Don't logoff games user).
check_enable_flag ($enable_flag);

; Get initial Day & Time parameters:
$daynum = @WDAY     ; day# of week: Su=1,M=2,T=3,W=3,Th=4,F=6,Sa=7
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
   Msgbox(0,'',"Weekday, Weekend Flags -- " & $weekday_flag &","& $weekend_flag, 3);
   Msgbox(0,'',"Day, Current Hour | login_start,end -- " & $daynum &","& $hour &" | "& $login_start &","& $login_stop, 5);
endif

; DAY Restrictions
; ================
; - check if today is a Restricted ay
;   eg: if (weekday is DISABLED (through week_flag from file))
;           and (today is a weekday (M-THU) )
;           then EXIT
;       else
;         Continue checking HOUR TIME Restrictions below.\
; Weekday # is 0-3 (M-THU)

; testing values
;;$daynum = 7

; Check WEEK DAY Restriction:
check_weekday_restriction ($weekday_flag, $daynum, $testing)

; Check WEEK END Restriction
check_weekend_restriction ($weekend_flag, $daynum, $testing)

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
$wait_loop_seconds = 60;                   ; # 60 seconds to Wait between Loops ("Delay")
$wait_loop_milliseconds = $wait_loop_seconds * 1000; ; # milliseconds to Wait between Loops
$wait_loop_default = $wait_loop_milliseconds;
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
	#comments-start
	if ($testing == 1) then
	    ;;$wait_loop_milliseconds = 7000;
		Msgbox(0, " ", "TESTING - Dif_wait and Time | Wait_ms == " & $dif_wait _
			   & "," & $hour & ", " & $minute & "," & $second & " | " & $wait_loop_milliseconds, 5);
	endif
	#comments-end

	; TIME RESTRICTIONS:
   ; ==================
	; for LOGIN start and Login end time
	; and LUNCH and DINNER start/stop
	; - do only for GAMES login username account
	;; if ( ($username == "games") _
	If ( ($hour < $login_start or $hour >= $login_stop or $hour == $hour_break1) _
   		   or ($hour >= $lunch_start and $hour < $lunch_stop) _
           or ($hour >= $dinner_start and $hour < $dinner_stop) _
           or ($hour >= $hour_stop)  ) Then

		 If ($hour >= $lunch_start and $hour < $lunch_stop)  Then
			Msgbox(0, " ", "... LUNCH TIME ...", 3);
		 elseif ($hour >= $dinner_start and $hour < $dinner_stop) Then
			Msgbox(0, " ", "... DINNER TIME ...", 3);
		 elseif ($hour >= $login_stop) Then
			   Msgbox(0, " ", "... It's almost Bed Time ...", 3);
		 Endif

		; Set LOG OFF flag
		 $stopping = 1

		; Stop right away if Before login:
		 if ($dif_wait < $wait_loop_milliseconds)  Then
			if ($testing == 0) then
			   Msgbox(0, " ", "...LOGIN NOT ALLOWED at this time ... LOGGING OFF..", 3);
			   sleep(3000);  	; milliseconds delay
			   if  NOT ($username == "rdavid" or $username == "digo") then
				  shutdown(16);   ; 16 == Logoff
			   else
				  Msgbox(0, " ", "...Disabled for user " & $username, 3);
			   endif
			   exit;
			endif
		 endif

	Else
		; OK here. NOT logging off.
		; .. KEEP LOOPING till TIME Restriction is found
		; .. ADJUST loop wait @ 11pm+ (23pm) late evening or early morning,
		;     for games:  loop less frequently to minimize load.
		;     for others: exit this script.
		 if ($hour >= 23 and $hour <= 7) Then
			if ($username == "games") then
			    $wait_loop_milliseconds = 1800 * 1000; ; # 30minutes == 1800sec to Wait between 11pm - 7am.
			elseif NOT ($username == "games") then
			   Msgbox(0, " ", "...EXITING script...", 3);
			   exit;
			endif
		 else
			$wait_loop_milliseconds = $wait_loop_default;  ; # normal/default loop wait on daytime.
		 endif

	Endif

	; LOG OFF or End Game the predefined time & hour:
	; .. Display Warning before Exiting.
	; =================================================

	if ($stopping == 1 ) Then

		SoundPlay(@WindowsDir & "\media\tada.wav", 1);  ; play sound before displaying Log off.
		Msgbox(0, " ", "...LOGGING OFF SOON...in 1 MINUTE", 3);
		sleep(60000);  ; 60,000 ms, 1 minute before Logging off.

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


; --- FUNCTIONS ----------------------------------------------------------

; Check Enable Flag 

Func check_enable_flag ($enable_flag)
   if ($enable_flag == 0) Then
       Msgbox(0,'',"Timer DISABLED... exiting.", 3);
       exit;
   endif
EndFunc


; Check WEEK DAY Restriction:

Func check_weekday_restriction ($weekday_flag, $daynum, $testing)
   ; Check WEEKDAY Restriction:
   ;  .. day #: M=2,T=3,W=3,Th=4
   if ( ($weekday_flag == 0) and ($daynum >=2 and $daynum <= 4)) Then
	  ; No weekday restriction
	  ; .. Exit now. Don't logoff games user.
	  if ($testing == 1) then
		 Msgbox(0,'',"WEEK DAY restriction DISABLED.. Exiting script now.", 3);
	  endif
	  exit;
   endif
EndFunc

; Check WEEK END Restriction:

Func check_weekend_restriction ($weekend_flag, $daynum, $testing)
   ; WeekEnd day #
   ; .. Sunday=1,Fri=6,Sat=7
   if ( ($weekend_flag == 0) and ($daynum == 1 or $daynum == 6 or $daynum == 7)) Then
	  ; No weekday restriction
	  ; .. Exit now. Don't logoff games user.
	  if ($testing == 1) then
		 Msgbox(0,'',"WEEK END restriction DISABLED.. Exiting script now.", 3);
	  endif
	  exit;
   endif
EndFunc

; ----------------
; We're done here.

; ----------------------------------------------------------
