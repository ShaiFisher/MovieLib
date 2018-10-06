#include <Constants.au3>
#include <File.au3>
#include <Misc.au3>

;
; AutoIt Version: 3.0
; Language:       English
; Platform:       Win9x/NT
; Author:         Jonathan Bennett (jon at autoitscript dot com)
;
; Script Function:
;   Runs videos selected in special web page:
;
;	Checks clipboard for movie file names
;	Run the videos (path should be in parent directory of the script directory)
;	Updates counter of times played in stats.js file
;
; stats.js example:
;	var stats = {
;	"test.avi":3,
;	"somefolder\\Chicken.Run2000DvDRipEng.avi":1,
;	};


$statsFilePath = "stats.js"
$MOVIES_FILE_PATH = 'movies.js'
Global $statsArray
Global $stringArray



Func writeStats($videoFilename)
   ; read stats file to array. remove first item which is the number of lines
   _FileReadToArray($statsFilePath, $statsArray)
   _ArrayDelete($statsArray, 0)
   $length = UBound($statsArray);

   ; replace \ with \\ (so it fit the script in the html file)
   $videoFilename = StringReplace($videoFilename, '\', '\\')

   ; search for movie file name
   Local $iIndex = _ArraySearch($statsArray, $videoFilename, 0,0,0,1)
   If $iIndex > 1 Then
	  ; found, increase counter
	  $line = $statsArray[$iIndex]
	  $countStr = StringRight($line, StringLen($line) - StringInStr($line, ":"))
	  $count = Int($countStr) + 1
	  $statsArray[$iIndex] = '"' & $videoFilename & '":' & $count & ','
	  _FileWriteFromArray($statsFilePath, $statsArray)
   Else
	  ; not found, add to file
	  ; replace last line with stats for this video
	  $statsArray[$length - 1] = '"' & $videoFilename & '":1,'
	  ; add last line to close json
	  _ArrayAdd($statsArray, '};')
   EndIf

   ; write back to file
   _FileWriteFromArray($statsFilePath, $statsArray)
EndFunc

Func runMovie($filename)
   ;popMsg('runMovie:' & $filename)
   writeStats($filename)
   If (StringMid ($filename,2,1) <> ':') Then
	  $filename = '..\' & $filename
   EndIf
   Run('openFile.bat "' & $filename & '"')
EndFunc

Func isMovieFileName($filename)
   $extension = StringRight($filename, 4)
   return $extension = '.avi' Or $extension = '.mp4' Or $extension = '.mkv' Or $extension = '.mpg' Or $extension = '.flv'
EndFunc

;https://youtu.be/s4XzVyhBP3Q
;https://www.youtube.com/watch?v=s4XzVyhBP3Q
Func isYoutubeClip($url)
   return StringLeft($url, 17) = 'https://youtu.be/' Or StringLeft($url, 29) = 'https://www.youtube.com/watch'
EndFunc

Func popMsg($message)
   MsgBox($MB_SYSTEMMODAL, "MovieLib", $message)
EndFunc

Func addYoutubeClip($url, $title)
   $pos = StringInStr($url, '?v=') + 2
   $id = StringRight($url, StringLen($url) - $pos)
   addMovieEntry($title, 'youtube', $id)
EndFunc

Func addMovieEntry($name, $type, $filename)
   ; read movies file to array. remove first item which is the number of lines
   _FileReadToArray($MOVIES_FILE_PATH, $stringArray)
   _ArrayDelete($stringArray, 0)
   $length = UBound($stringArray);

   $filename = StringReplace($filename, '\', '\\')

   ; replace last line with record for this video
   Local $entry
   If ($type = 'youtube') Then
	  $entry = "	{'name': '" & $name & "', 'type': 'youtube', 'id': '" & $filename & "'},"
   Else
	  $entry = "	{'name': '" & $name & "', 'type': '" & $type & "', 'video': '" & $filename & "'},"
   EndIf
   $stringArray[$length - 1] = $entry

   ; add last line to close json
   _ArrayAdd($stringArray, '];')

   ; write back to file
   _FileWriteFromArray($MOVIES_FILE_PATH, $stringArray)
EndFunc

Func stripFileName($filename)
   $pos = StringInStr($filename, '\')
   while ($pos > 0)
	  $filename = StringRight($filename, StringLen($filename) - $pos)
	  $pos = StringInStr($filename, '\')
   WEnd

   ; remove extension
   $filename = StringLeft($filename, StringLen($filename) - 4)

   Return $filename
EndFunc


;--------------------------------------------------

; init - open html file
;Run('openFile.bat "movieLib.html"')


; Enforce singleton
If _Singleton("test", 1) = 0 Then
	popMsg('Already Running')
    Exit
EndIf


$prevClipData = 'bla'

While 1=1
   ; read clipboard
   $clipData = ClipGet()
   ; check if clipData has been changed
   If $clipData <> $prevClipData Then
		$prevClipData = $clipData

	  If StringLeft($clipdata, 9) = 'MovieLib:' Then
		 If StringLeft($clipData, 14) = 'MovieLib:play:' Then
			; run movie
			$filename = StringRight($clipData, StringLen($clipData) - 14)
			runMovie($filename)
		 ElseIf StringLeft($clipData, 14) = 'MovieLib:stat:' Then
			; write stat
			$filename = StringRight($clipData, StringLen($clipData) - 14)
			;popMsg('stat:' & $filename)
			writeStats($filename)
		 EndIf
		 $clipData = ''
	  ElseIf isYoutubeClip($clipData) Then
		 ;popMsg('YouTube clip: ' & $clipData)
		 Local $title = InputBox("Add clip to MovieLib", "Please enter the title")
		 If $title <> '' Then
			 addYoutubeClip($clipData, $title)
			 $clipData = ''
		  EndIf
	  ElseIf isMovieFileName($clipData) Then
		 ;popMsg($clipData)
		 Local $strippedFileName = stripFileName($clipData)
		 Local $title = InputBox("Add movie to MovieLib", "Please enter the title", $strippedFileName)
		 If $title <> '' Then
			addMovieEntry($title, 'movie', $clipData)
			$clipData = ''
		 EndIf
	  EndIf
   EndIf

	Sleep ( 1000 )
WEnd