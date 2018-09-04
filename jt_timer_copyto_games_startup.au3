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
#comments-start   (comments start)
10   ; == login_start
21   ;     login_stop
11   ; == lunch_start
13   ;     lunch-stop
15   ; == hour_break
18   ; == dinner_start
20   ;     dinner_stop
1    ; Weekdays(1) enable / disable(0) Restriction
1   ; Friday/Weekends(1) enable / disable(0)
1   ; Enable Script (1)/disable(0) Time Restrictions
#comments-end  (comments end)

; Read File Line by line:
$total_lines = _FileCountLines($file)
;;Msgbox(0,'',"total lines in file -- " & $total_lines, 3);

For $i = 1 to $total_lines

	  $line = FileReadLine($file, $i);   ; tag: "Readfile"
      ; Split string to an Array.
	  ;   Array_var[0] == # of chars read
	  ;   Array[var[1] == values read before the Delimeter
	  $time_read_array = Stringsplit($line, ";");
	  $time_read = StringStripWS($time_read_array[1],8);  ; remove whitespace (All flag: 8)
	  if ($testing == 1) then
		 Msgbox(0,'',"line# -- " & $i& " -- | line read, time read -- " & $line & " ==  "& $time_read, 1);
	  endif

	  if ($i == 1) Then
		 $login_start = $time_read;
	  elseif ($i == 2) Then
		 $login_stop = $time_read;
	  elseif ($i == 3) Then
		 $lunch_start = $time_read;
	  elseif ($i == 4) Then
		 $lunch_stop = $time_read;
	  elseif ($i == 5) Then
		 $hour_break1 = $time_read;
   	  elseif ($i == 6) Then
		 $dinner_start = $time_read;
   	  elseif ($i == 7) Then
		 $dinner_stop = $time_read;
	  elseif ($i == 8) Then
		 $weekday_flag = $time_read;    ; weekday flag
	  elseif ($i == 9) Then
		 $weekend_flag = $time_read;    ; Fridays & Weekend flag
	  elseif ($i == 10) Then
		 $enable_flag = $time_read;
		 checkNumeric($enable_flag);
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
if ($login_start < 10) Then
    $login_start = "0" & $login_start;
 endif

; Display read values:
if ($testing == 1) then
   Msgbox(0,'',"Weekday, Weekend Flags -- " & $weekday_flag &","& $weekend_flag, 1);
   Msgbox(0,'',"Day, Current Hour | login_start,end -- " & $daynum &","& $hour &" | "& $login_start &","& $login_stop, 2);
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
           or ($hour >= $dinner_start and $hour < $dinner_stop) )  Then

		 ; Set Secondary flag for logging off.
		 $stop_now = 1;

         ;; For LUCHTIME:
		 If ($hour >= $lunch_start and $hour < $lunch_stop)  Then
			; Logoff LUNCHTIME starting @ 11:30am -- special case:
			if ($hour == 11) Then
			   if ($minute >= 30) Then
				  Msgbox(0, " ", "... Prepare for LUNCHTIME ...", 3);
			   else
				  ; Too early for Lunch
				  ; .. Not yet 11:30am+, so don't logoff yet.
				  $stop_now = 0;
				  $stopping = 0;
			   endif
			else
			   ;  LUNCTIME, Log off now.
			   Msgbox(0, " ", "... LUNCH TIME ...", 3);
			endif

         ;; For DINNER TIME:
		 elseif ($hour >= $dinner_start and $hour < $dinner_stop) Then
			; Logoff Dinner starting @ 6:30pm -- special case:
			if ($hour == 18) Then
			   if ($minute >= 30) Then
				  Msgbox(0, " ", "... 6:30 - 7pm -- Prepare for DINNER ...", 3);
			   else
				  ; Too early for dinner.
				  ; .. Not yet 6:30pm+, so don't logoff yet.
				  $stop_now = 0;
				  $stopping = 0;
			   endif
			else
			   ; For Other Dinner time, eg: 7-8pm:
			   Msgbox(0, " ", "... DINNER Time ...", 3);
			endif
		 elseif ($hour >= $login_stop) Then
			   Msgbox(0, " ", "... It's almost Bed Time ...", 3);
		 endif

		; Set LOG OFF flag
		if ($stop_now == 1) then
			$stopping = 1
	    endif;

		; Stop right away if Before login:
		 if ( ($dif_wait < $wait_loop_milliseconds) and ($stopping == 1) ) Then
			if ($testing == 0) then
			   Msgbox(0, " ", "...LOGIN NOT ALLOWED at this time ... LOGGING OFF..", 3);
			   sleep(5000);  	; milliseconds delay
			   if  ($username == "games") then
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
		; For LATE AT NIGHT:
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

Func checkNumeric ($flag)
      if NOT (StringIsDigit($flag)) Then
		 Msgbox(0,'',"ERROR: Flag " & $flag & " is NOT numeric.", 5);
		 exit;
	  endif
EndFunc

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
