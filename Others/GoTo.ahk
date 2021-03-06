/*
#####################
GoTo v0.9
Avi Aryan
#####################

Go To functions, labels, hotkeys and hotstrings in any editor.
The only requirement is that the Editor shows file full path in Title Bar and has a Goto (Ctrl+G) option.
Examples of such editors - Notepad++, Sublime Text, PSPad, ConTEXT

Any script which shows the full path and has a goto option is vaild

*/

;------- CONFIGURE -------------------
GoTo_AutoExecute(1, A_temp)		;1 = Gui is movable, A_temp = Working Directory

#if GetActiveFile()		;If ahk window is active
	F7::Goto_Main_Gui()
#if
;-------------------------------------
return

GoTo_AutoExecute(resizable=true, WorkingDir=""){
global

	SetWorkingDir,% ( WorkingDir == "" ) ? A_scriptdir : WorkingDir
	SetBatchLines, -1
	FileCreateDir, gotoCache
	FileDelete, gotoCache\*.gotolist
	SetTimer, filecheck, 200
	goto_cache := {}
	if resizable
		OnMessage(0x201, "DragGotoGui") ; WM_LBUTTONDOWN
}

GoTo_Readfile(File) {
	Critical, On

	static filecount , commentneedle := A_space ";|" A_tab	";"
	
	if ( filecount_N := fileiscached(File) )
		Filename := filecount_N
	else
	{
		Filename := filecount := filecount ? filecount+1 : 1
		FileAppend,% file "`n",gotoCache\filelist.gotolist
	}
	FileDelete, gotoCache\%Filename%-*

	loop, read, %file%
	{
		readline := Trim( A_LoopReadLine )
		if block_comments
			if Instr(readline, "*/") = 1
			{
				block_comments := 0
				continue
			}
			else continue

		if Instr(readline, ";") = 1
			continue

		if Instr(readline, "/*") = 1
		{
			block_comments := 1
			continue
		}
		
		readline := Trim( Substr(readline, 1, SuperInstr(readline, commentneedle, 1) ? SuperInstr(readline, commentneedle, 1)-1 : Strlen(readline)) )

		if ( readline_temp := Check4Hotkey(readline) )
			CreateCache(filename, "hotkey", readline_temp, A_index)
		else if ( Instr(readline, ":") = 1 ) and ( Instr(readline, "::", 0, 0) > 1 )
			CreateCache(filename, "hotstr", Substr(readline, 1, Instr(readline, "::", 0, 0)-1), A_index )
		else if !SuperInstr(readline, "``|`t| |,", 0) and Substr(readline,0) == ":"
			CreateCache(filename, "label", readline, A_index)
		else if Check4func(readline, A_index, file)
			CreateCache(filename, "func", Substr(readline, 1, Instr(readline, "(")) ")", A_index)
	}
	SortCache(filename)
}

CreateCache(hostfile, type, data, linenum){
	if type = func
		if ( Substr( data, 1, SuperInstr(data, " |`t|,|(", 1)-1 ) == "while" )
			return
	;Exceptions are listed above

	FileAppend,% data ">" linenum "`n",% "Gotocache\" hostfile "-" type ".gotolist"
}

Check4Hotkey(line) {
;The function assumes line is trimmed using Trim() and then checked for ; comment

	if ( Instr(line, "::") = 1 ) and ( Instr(line, ":", false, 0) = 3 )		;hotstring
		return ""
	hK := Substr( line, 1, ( Instr(line, ":::") ? Instr(line, ":::")+2 : ( Instr(line, "::") ? Instr(line, "::")+1 : Strlen(line)+2 ) ) - Strlen(line) - 2)
	if hK = 
		return

	if !SuperInstr(hK, " |	", 0)
		if !SuperInstr(hK, "^|!|+|#", 0) And RegExMatch(hK, "[a-z]+[,(]")
			return
		else
			return hK
	else
		if Instr(hK, " & ") or ( Substr(hK, -1) == "UP" )
			return hK
}


Check4func(readline, linenum, file){

	if RegExmatch(readline, "i)[A-Z0-9#_@\$\?\[\]]+\(.*\)") != 1
		return
	if ( Substr(readline, 0) == "{" )
		return 1

	loop,
	{
		FileReadLine, cl, %file%,% linenum+A_index
		if Errorlevel = 1
			return
		cl := Trim( Substr(cl, 1, Instr(cl, ";") ? Instr(cl, ";")-1 : Strlen(cl)) )
		if cl = 
			continue

		if block_comments
			if Instr(readline, "*/") = 1
			{
				block_comments := 0
				continue
			}
			else continue
		
		if Instr(readline, "/*") = 1
		{
			block_comments := 1
			continue
		}

		return Instr(cl, "{") = 1 ? 1 : 0
	}
}

filecheck:
	FileGetTime, Timeforfile,% goto_tempfile := GetActiveFile(), M
	if ( goto_cache[goto_tempfile] != Timeforfile )
		goto_cache[goto_tempfile] := Timeforfile , Goto_Readfile(goto_tempfile)
	return

fileiscached(file){
	loop, read, gotoCache\filelist.gotolist
		if ( file == A_LoopReadLine )
			return A_index
}

;-------------------------------------- GUI --------------------------------------------------------------

Goto_Main_GUI()
{
	global
	static IsGuicreated , Activefile_old
	
	Activefileindex := fileiscached( GetActiveFile() )
	
	if ( Activefile_old != Activefileindex )
	{
		Guicontrol, Goto:, Mainlist,% "|"
		Guicontrol, Goto:Choose, maintab, 1
		Update_GUI("-label", activefileindex)
	}
	
	if !IsGuicreated
	{
		Gui, Goto:New
		Gui, +AlwaysOnTop -Caption +ToolWindow
		Gui, Margin, 3, 3
		Gui, Font, s11, Consolas
		Gui, Add, Tab2,% "w" 310 " h30 vmaintab gtabclick AltSubmit", Labels|Functions|Hotkeys|Hotstrings
		Gui, Tab
		Gui, Font, s10, Courier New
		Gui, Add, DropDownList,% "xs y+10 h30 r20 vMainList gDDLclick Altsubmit w" 300
		Update_GUI("-label", activefileindex)
		IsGuicreated := 1
	}
	if !WinExist("GoTo ahk_class AutoHotkeyGUI")
		Gui, Goto:Show,, GoTo
	else
		Gui, Goto:Hide
	Activefile_old := Activefileindex
	return

DDLclick:
	Gui, Goto:submit, nohide
	GoToMacro(ActivefileIndex, Typefromtab(Maintab), Mainlist)
	return

tabClick:
	Gui, Goto:submit, nohide
	Update_GUI(Typefromtab(maintab), Activefileindex)
	return

GotoGUIEscape:
	Gui, Goto:Hide
	return
}

Update_GUI(mode, fileindex){
	if !fileindex
		return
	loop, read, gotoCache\%fileIndex%%Mode%.gotolist
		MainList .= "|" Substr(A_loopreadline, 1, Instr(A_loopreadline, ">", 0, 0)-1)
	Guicontrol, Goto:,Mainlist,% !MainList ? "|" : Mainlist
}

GoToMacro(Fileindex, type, linenum){
	BlockInput, On
	Gui, Goto:Hide
	Filereadline, cl, gotocache\%Fileindex%%type%.gotolist, %linenum%
	runline := Substr(cl, Instr(cl, ">", 0, 0)+1)
	SendInput, ^g
	sleep, 100
	SendInput,% runline "{Enter}"
	BlockInput, Off
}
;---------------------------------------------------------------------------------------------------------

GetActiveFile(){
	WinGetActiveTitle, Title
	if !( Instr(title, ".ahk") and Instr(title, ":\") )
		return ""
	return Trim( Substr( Title, temp := Instr(Title, ":\")-1, Instr(Title, ".ahk", 0, 0)-temp+4 ) ) 
}

TypefromTab(TabCount){

	if Tabcount = 1
		return "-label"
	else if Tabcount = 2
		return "-func"
	else if Tabcount = 3
		return "-hotkey"
	else
		return "-hotstr"
}

SortCache(file){

	static type := "label,func,hotkey,hotstr"
	loop, parse, type,`,
	{
		FileRead, ovar,% "gotocache\" file "-" A_LoopField ".gotolist"
		Sort, ovar
		FileDelete,% "gotocache\" file "-" A_LoopField ".gotolist"
		FileAppend,% ovar,% "gotocache\" file "-" A_LoopField ".gotolist"
	}
}

DragGotoGui(){		;Thanks Pulover
	PostMessage, 0xA1, 2,,, A
}

;Helper Function(s) --------------------------------------------------------------------------------------
/*
SuperInstr()
	Returns min/max position for a | separated values of Needle(s)
	
	return_min = true  ; return minimum position
	return_min = false ; return maximum position

*/

SuperInstr(Hay, Needles, return_min=true, Case=false, Startpoint=1, Occurrence=1){
	
	pos := return_min*Strlen(Hay)
	if return_min
	{
		loop, parse, Needles,|
			if ( pos > (var := Instr(Hay, A_LoopField, Case, startpoint, Occurrence)) )
				pos := var ? var : pos
		if ( pos == Strlen(Hay) )
			return 0
	}
	else
	{
		loop, parse, Needles,|
			if ( (var := Instr(Hay, A_LoopField, Case, startpoint, Occurrence)) > pos )
				pos := var
	}
	return pos
}