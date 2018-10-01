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
Global $statsArray

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
   writeStats($filename)
   Run('openFile.bat "..\' & $filename & '"')
EndFunc



; init - open html file
Run('openFile.bat "movieLib.html"')


; Enforce singleton
If _Singleton("test", 1) = 0 Then
    Exit
EndIf


$prevClipData = 'bla'

While 1=1
	; read clipboard
	$clipData = ClipGet()
	; check if clipData has been changed
	If $clipData <> $prevClipData Then
		$prevClipData = $clipData

		; check if text is video file name
		$extension = StringRight($clipData, 4)
		If $extension = '.avi' Or $extension = '.mp4' Or $extension = '.mkv' Or $extension = '.mpg' Or $extension = '.flv' Then
			;MsgBox($MB_SYSTEMMODAL, "AutoIt Example", $clipData)
			runMovie($clipData);
		EndIf
	EndIf

	Sleep ( 1000 )
WEnd