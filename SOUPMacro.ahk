#Requires AutoHotkey v2.0
#SingleInstance Force

/*
major_version := 0
minor_version := 0
patch_version := 0
label := "alpha"
*/

global MacroButtonAmount := 8

global PATH_DIR := A_MyDocuments
global FOLDER_TREE := {
    SOUP_Macros: {
        Macros: [],
        Modules: [],
        Utils: [],
        Storage: []
    }
}

global Version := "1.0.0"
;global Menu_Version := major_version "." minor_version "." patch_version (label != "" ? "-" label : "")

global GITHUB_API_URL := "https://api.github.com/repos/ur-lucky/SOUP_Macros/contents/"
global GITHUB_RAW_URL := "https://raw.githubusercontent.com/ur-lucky/SOUP_Macros/main/"


global CurrentPage := 1
global PageWhenButtonClicked := -1
global MacroButtonSelected := -1
global MainGui_MacroButtonArray := []
global MainGui_MacroInfoArray := []
;global MacroArray := []
global ProcessedDependencies := []


global MacroArray := Array()
global MacroObjects := Map()
global LocalMacros := Map()


global ColorMap := Map()
ColorMap["Unknown"] := "0x858585"
ColorMap["Stable"] := "0x2bff0f"
ColorMap["Unstable"] := "0xffb10a"
ColorMap["Unsupported"] := "0x9b6fee"
ColorMap["Non-functional"] := "0xff1a1a"

QuickGui := Gui(Options := "+AlwaysOnTop -Caption -SysMenu", Title := "Preload")
QuickGui.SetFont("s15 w450 q2", "Cascadia Code")
QuickGuiText := QuickGui.AddText("Center w450")

RedrawQuickGui(NewText := "text", Duration := 0) {
    QuickGuiText.Text := NewText
    ;QuickGuiText.Redraw()
    QuickGui.Show()

    if (Duration != 0) {
        SetTimer(QuickGui.Hide(), -Duration)
    }
}

; Core functions

TimeToString(IsoTime) {
    Reformatted := ""

    Split1 := StrSplit(IsoTime, "T")
    Split2 := StrSplit(Split1[1], "-")
    Reformatted := Split2[1] Split2[2] Split2[3]

    Split3 := StrSplit(Split1[2], "Z")
    Split4 := StrSplit(Split3[1], ":")
    Reformatted := Reformatted Split4[1] Split4[2] Split4[3]

    ; Calculate the time difference in different units
    DaysDiff := DateDiff(A_NowUTC, Reformatted, "Days")
    HoursDiff := DateDiff(A_NowUTC, Reformatted, "Hours")
    MinutesDiff := DateDiff(A_NowUTC, Reformatted, "Minutes")

    ; Determine the most relevant time unit
    if (DaysDiff > 0) {
        return {Time: DaysDiff, Word: DaysDiff = 1 ? "Day" : "Days"}
    } else if (HoursDiff > 0) {
        return {Time: HoursDiff, Word: HoursDiff = 1 ? "Hour" : "Hours"}
    } else if (MinutesDiff > 0) {
        return {Time: MinutesDiff, Word: MinutesDiff = 1 ? "Minute" : "Minutes"}
    } else {
        return {Time: "A Couple", Word: "Seconds"}
    }
}




StrJoin(array, seperator) {
    filePath := ""

    for index, element in array {
        if index > 1 {
            filePath .= "\"
        }
        filePath .= element
    }

    return filePath
}

ExtractVersion(Text) {
    if RegExMatch(Text, 'Version\s*:=\s*"(.*?)"', &match) {
        return match[1]
    }
    return "?"
}

ExtractText(str, find) {
    if RegExMatch(str, find '\s*:=\s*"(.*?)"', &match) {
        return match[1]
    }
    return ""
}

VersionCheck(old, new) {
    OldVersion := ExtractVersion(old)
    NewVersion := ExtractVersion(new)

    if OldVersion = NewVersion {
        return {Changed: false, Old: OldVersion, New: NewVersion}
    } else {
        return {Changed: true, Old: OldVersion, New:NewVersion}
    }
}

Jxon_Load(&src, args*) {
	key := "", is_key := false
	stack := [ tree := [] ]
	next := '"{[01234567890-tfn'
	pos := 0
	
	while ( (ch := SubStr(src, ++pos, 1)) != "" ) {
		if InStr(" `t`n`r", ch)
			continue
		if !InStr(next, ch, true) {
			testArr := StrSplit(SubStr(src, 1, pos), "`n")
			
			ln := testArr.Length
			col := pos - InStr(src, "`n",, -(StrLen(src)-pos+1))

			msg := Format("{}: line {} col {} (char {})"
			,   (next == "")      ? ["Extra data", ch := SubStr(src, pos)][1]
			  : (next == "'")     ? "Unterminated string starting at"
			  : (next == "\")     ? "Invalid \escape"
			  : (next == ":")     ? "Expecting ':' delimiter"
			  : (next == '"')     ? "Expecting object key enclosed in double quotes"
			  : (next == '"}')    ? "Expecting object key enclosed in double quotes or object closing '}'"
			  : (next == ",}")    ? "Expecting ',' delimiter or object closing '}'"
			  : (next == ",]")    ? "Expecting ',' delimiter or array closing ']'"
			  : [ "Expecting JSON value(string, number, [true, false, null], object or array)"
			    , ch := SubStr(src, pos, (SubStr(src, pos)~="[\]\},\s]|$")-1) ][1]
			, ln, col, pos)

			throw Error(msg, -1, ch)
		}
		
		obj := stack[1]
        is_array := (obj is Array)
		
		if i := InStr("{[", ch) { ; start new object / map?
			val := (i = 1) ? Map() : Array()	; ahk v2
			
			is_array ? obj.Push(val) : obj[key] := val
			stack.InsertAt(1,val)
			
			next := '"' ((is_key := (ch == "{")) ? "}" : "{[]0123456789-tfn")
		} else if InStr("}]", ch) {
			stack.RemoveAt(1)
            next := (stack[1]==tree) ? "" : (stack[1] is Array) ? ",]" : ",}"
		} else if InStr(",:", ch) {
			is_key := (!is_array && ch == ",")
			next := is_key ? '"' : '"{[0123456789-tfn'
		} else { ; string | number | true | false | null
			if (ch == '"') { ; string
				i := pos
				while i := InStr(src, '"',, i+1) {
					val := StrReplace(SubStr(src, pos+1, i-pos-1), "\\", "\u005C")
					if (SubStr(val, -1) != "\")
						break
				}
				if !i ? (pos--, next := "'") : 0
					continue

				pos := i ; update pos

				val := StrReplace(val, "\/", "/")
				val := StrReplace(val, '\"', '"')
				, val := StrReplace(val, "\b", "`b")
				, val := StrReplace(val, "\f", "`f")
				, val := StrReplace(val, "\n", "`n")
				, val := StrReplace(val, "\r", "`r")
				, val := StrReplace(val, "\t", "`t")

				i := 0
				while i := InStr(val, "\",, i+1) {
					if (SubStr(val, i+1, 1) != "u") ? (pos -= StrLen(SubStr(val, i)), next := "\") : 0
						continue 2

					xxxx := Abs("0x" . SubStr(val, i+2, 4)) ; \uXXXX - JSON unicode escape sequence
					if (xxxx < 0x100)
						val := SubStr(val, 1, i-1) . Chr(xxxx) . SubStr(val, i+6)
				}
				
				if is_key {
					key := val, next := ":"
					continue
				}
			} else { ; number | true | false | null
				val := SubStr(src, pos, i := RegExMatch(src, "[\]\},\s]|$",, pos)-pos)
				
                if IsInteger(val)
                    val += 0
                else if IsFloat(val)
                    val += 0
                else if (val == "true" || val == "false")
                    val := (val == "true")
                else if (val == "null")
                    val := ""
                else if is_key {
                    pos--, next := "#"
                    continue
                }
				
				pos += i-1
			}
			
			is_array ? obj.Push(val) : obj[key] := val
			next := obj == tree ? "" : is_array ? ",]" : ",}"
		}
	}
	
	return tree[1]
}

GetRawFromURL(url) {
    OutputDebug("[DEBUG] | MAKING A REQUEST")
    retries := 6  ; Number of retries

    retryWaitTime := 10000

    RawResponse := ""
    
    Loop retries {
        try {
            Download := ComObject("WinHttp.WinHttpRequest.5.1")
            Download.Open("GET", url, true)
            Download.Send()
            Download.WaitForResponse()

            OutputDebug("[DEBUG] | DOWNLOAD | " Download.Status " | " Download.StatusText " | ")
            
            RawResponse := Download.ResponseText

            if (Download.Status != 200) {
                OutputDebug("[DEBUG] | API LIMIT | " RawResponse)

                timeElapsed := 0
                startTick := A_TickCount

                
                QuickGui.Show()

                while timeElapsed <= retryWaitTime {
                    timeElapsed := A_TickCount - startTick
                    QuickGuiText.Text := "Retrying in... " . Round((retryWaitTime - timeElapsed) / 1000)
                    Sleep(90)
                }

                QuickGuiText.Text := "Retrying..."
                Sleep(1000)

                continue
            } else {
                return RawResponse
            }

            ;OutputDebug("[DEBUG] | RAW RESPONSE | " RawResponse)

            ; Check if the response contains rate limit exceeded message
        } catch Error as err {
            MsgBox("Error while downloading: " err.Message, "Error", "0x30")
        }
    }

    ; If all retries failed
    MsgBox "Failed to download after multiple attempts due to rate limit."
    return ""
}

GetFilesFromGithub(pathArray, downloadFiles := false) {
    ; Build the URL for the GitHub API
    urlPath := GITHUB_API_URL . StrReplace(StrJoin(pathArray, "/"), "\", "/")  ; Use "/" for GitHub API paths
    raw := GetRawFromURL(urlPath)

    ; Load the API response into a JSON object
    apiResponse_JSON := Jxon_Load(&raw)
    if (!apiResponse_JSON || !IsObject(apiResponse_JSON)) {
        MsgBox "Failed to fetch file list from GitHub."
        return
    }

    FileMap := Map()

    ; Loop through the response to check for files and directories
    for _, file in apiResponse_JSON {
        ; Ensure each file is an object before using it
        if IsObject(file) && file.Has("type") {
            if (file["type"] = "file") {
                fileName := file["name"]
                fileUrl := GITHUB_RAW_URL . file["path"]  ; Full file path for GitHub raw URL
                
                RawFile := downloadFiles ? GetRawFromURL(fileUrl) : ""

                FileMap[file["path"]] := RawFile  ; Store the full path and file content
            
            } else if (file["type"] = "dir") {
                ; Recursively fetch files from the directory
                subDirPath := pathArray.Join("/") . "/" . file["name"]  ; Build sub-directory path
                subDirFiles := GetFilesFromGithub([subDirPath], downloadFiles)
                
                ; Merge subdirectory files into the FileMap
                for subFilePath, subFileContent in subDirFiles {
                    FileMap[subFilePath] := subFileContent
                }
            }
        } else {
            MsgBox "Invalid file entry in the API response. Expected object, got " Type(file)
        }
    }

    return FileMap
}

GetDependency(dependencyString) {
    urlPath := GITHUB_RAW_URL . StrReplace(dependencyString, "\", "/")  ; Use "/" for GitHub API paths
    raw := GetRawFromURL(urlPath)
    return raw
}

DependencyCheck(fileContent) {
    dependencies := []
    startPos := 1  ; Initialize start position for RegExMatch

    OutputDebug("[DEBUG] | CHECKING FOR DEPENDENCIES...")

    ; Main regular expression to find the array of dependencies
    if RegExMatch(fileContent, 'i)Dependencies\s*:=\s*\[([^\]]+)\]', &match) {
        dependencyList := match[1]  ; The string inside the square brackets

        OutputDebug("[DEBUG] | FOUND DEPENDENCIES")

        ; Extract individual dependencies inside quotes
        while RegExMatch(dependencyList, '"([^"]+)"', &depMatch, startPos) {
            dependencies.Push(depMatch[1])  ; Add the dependency to the array
            startPos := depMatch.Pos + StrLen(depMatch[0])  ; Move after the current match
        }
    } else {
        OutputDebug("[DEBUG] | NO DEPENDENCIES FOUND")
    }

    return dependencies
}

ProcessDependencies(rawFileContent) {
    dependencies := DependencyCheck(rawFileContent)
    
    if (dependencies.Length = 0) {
        OutputDebug("[DEPENDENCY] No dependencies found.")
        return
    }
    
    for _, dependencyPath in dependencies {
        dependencyFileName := StrSplit(dependencyPath, "\")[StrSplit(dependencyPath, "\").Length]
        dependencyName := StrSplit(dependencyFileName, ".")[1]
        localPath := PATH_DIR . "\SOUP_Macros\" . dependencyPath
        
        rawDependency := GetDependency(dependencyPath)
        
        if FileExist(localPath) {
            VersionCheckResults := VersionCheck(FileRead(localPath), rawDependency)
            if (VersionCheckResults.Changed) {
                FileDelete(localPath)
                FileAppend(rawDependency, localPath, "UTF-8-RAW")
            }
        } else {
            FileAppend(rawDependency, localPath, "UTF-8-RAW")
        }

        ; Output debug information about the processed dependency
        OutputDebug("[DEPENDENCY] Processed | " dependencyName)
    }
}

CreateFolders(BasePath, FolderTree) {
    for folder, subFolders in FolderTree.OwnProps() {
        fullPath := BasePath "\" folder
        DirCreate(fullPath)
        if IsObject(subFolders) {
            CreateFolders(fullPath, subFolders)
        }
    }
}

; UI Functions

UpdateMacroPage() {
    global CurrentPage
    global MacroArray
    global MacroButtonAmount

    TotalMacros := MacroArray.Length
    MaxPages := Ceil(TotalMacros / MacroButtonAmount)

    Loop MacroButtonAmount {
        MacroIndexNumber := (CurrentPage * MacroButtonAmount) - MacroButtonAmount + A_Index
        OutputDebug("[DEBUG] MACRO INDEX NUMBER " MacroIndexNumber)
        button := MainGui_MacroButtonArray.Get(A_Index)
        if MacroArray.Has(MacroIndexNumber) {
            macroObj := MacroArray.Get(MacroIndexNumber)
            button.Text := macroObj.name
            button.Visible := true
        } else {
            button.Visible := false
        }
    }
    MainGui_MacroPageNumber.Text := CurrentPage . "/" . (MaxPages = 0 ? 1 : MaxPages)
}

ChangeMacroPage(Index := "Next") {
    global CurrentPage
    global MacroArray
    global MacroButtonAmount

    TotalMacros := MacroArray.Length
    MaxPages := Ceil(TotalMacros / MacroButtonAmount)

    if (TotalMacros <= MacroButtonAmount) {
        return
    }

    switch Index {
        case "Next":
            if (CurrentPage + 1) > MaxPages {
                CurrentPage := 1
                UpdateMacroPage()
                return
            }
            CurrentPage += 1
            UpdateMacroPage()
        case "Previous":
            if (CurrentPage - 1) <= 0 {
                CurrentPage := MaxPages
                UpdateMacroPage()
                return
            }
            CurrentPage -= 1
            UpdateMacroPage()
    }
}

MacroButtonClicked(ButtonNumber) {
    global CurrentPage
    global PageWhenButtonClicked
    global MacroButtonSelected

    OutputDebug("[DEBUG] MacroButtonSelected: " MacroButtonSelected " | New button: " ButtonNumber)

    if (CurrentPage = PageWhenButtonClicked) and (MacroButtonSelected = ButtonNumber) {
        return ; user clicked on the same button
    }

    PageWhenButtonClicked := CurrentPage
    MacroButtonSelected := ButtonNumber

    MacroIndex := (CurrentPage * MacroButtonAmount) - MacroButtonAmount + ButtonNumber
    macroObj := MacroArray.Get(MacroIndex)

    MainGui_MacroInfo_MacroName.Text := macroObj.name
    MainGui_MacroInfo_MacroVersion.Text := "v" macroObj.version
    MainGui_MacroInfo_MacroDescription.Text := macroObj.description
    MainGui_MacroInfo_MacroStatus.Text := macroObj.status

    if ColorMap.Has(macroObj.status) {
        MainGui_MacroInfo_MacroStatus.SetFont("s11 Bold q4 c" ColorMap[macroObj.status], "Cascadia Code")
    }

    MainGui_MacroInfo_MacroLastUpdate.Text := macroObj.last_updated

    if macroObj.initial_fetch_complete {
        MainGui_MacroInfo_RunMacro.Enabled := true
        MainGui_MacroInfo_RunMacro.Text := "Run Macro"
    } else {
        MainGui_MacroInfo_RunMacro.Enabled := false
        MainGui_MacroInfo_RunMacro.Text := "[Fetching...]"
    }

    for _, uiElement in MainGui_MacroInfoArray {
        uiElement.Visible := true
    }

    ;if RegExMatch(macroObj.LastUpdated, "Fetch|Failed") > 0 {
    if not macroObj.initial_fetch_complete {
        MainGui_MacroInfo_MacroLastUpdate.Text := "[Fetching...]"
        GetExtraMacroInformation(macroObj)  ; Fetch the data if not already fetched
        if (CurrentPage = PageWhenButtonClicked) and (MacroButtonSelected = ButtonNumber) {
            MainGui_MacroInfo_MacroLastUpdate.Text := macroObj.last_updated
            MainGui_MacroInfo_RunMacro.Text := "Run Macro"
            MainGui_MacroInfo_RunMacro.Enabled := true
        }
        ;MainGui_MacroInfo_RunMacro.Text := "Run"
    }
}

RunButtonClicked() {
    global PageWhenButtonClicked
    global MacroButtonSelected

    MacroIndex := (PageWhenButtonClicked * MacroButtonAmount) - MacroButtonAmount + MacroButtonSelected
    macroObj := MacroArray.Get(MacroIndex)

    if not macroObj.HasOwnProp("local_path") {
        switch MsgBox(
            "Macro `"" macroObj.name "`" is missing.`nWould you like to install it?", 
            "SOUP Macros", 
            "0x1032 0x4"
        ) {
            case "Yes":
                newFile := GetDependency(macroObj.path)
                newPath := A_MyDocuments . "\SOUP_Macros\" . macroObj.path
                macroObj.raw_file := newFile
                macroObj.local_path := newPath

                FileAppend(newFile, newPath, "UTF-8-RAW")
                MsgBox("Installed " macroObj.name)
            case "No":
                return
        }
    } else if macroObj.HasOwnProp("local_version") {
        if macroObj.version != macroObj.local_version {
            switch MsgBox(
                "Macro `"" macroObj.name "`" was updated `nWould you like to update?",
                "SOUP Macros", 
                "0x1032 0x4"
            ) {
                case "Yes":
                    FileDelete(macroObj.local_path)
                    newFile := GetDependency(macroObj.path)
                    macroObj.raw_file := newFile
                    FileAppend(newFile, macroObj.local_path, "UTF-8-RAW")
                    MsgBox("Updated macro")
                default:
                    MsgBox("Keeping the current version & running")
            }
        }
    }

    FilePath := PATH_DIR . "\SOUP_Macros\Macros\"

    RedrawQuickGui("Ensuring dependencies are loaded")
    ProcessDependencies(macroObj.raw_file)
    QuickGui.Hide()

    Run(macroObj.local_path)

    ExitApp()
}

GetExtraMacroInformation(MacroObj) {
    ; Create a placeholder for storing commit history and last update information
    MacroObj.commit_history := []
    MacroObj.last_updated := "[Fetching...]"

    ; Fetch the last update time and commit history from the GitHub API
    try {
        APILink := "https://api.github.com/repos/ur-lucky/SOUP_Macros/commits?path=Macros/" MacroObj.name ".ahk&page=1&per_page=25"
        APIDownload := ComObject("WinHttp.WinHttpRequest.5.1")
        APIDownload.Open("GET", APILink, true)
        APIDownload.Send()
        APIDownload.WaitForResponse()

        ; Parse the JSON response
        ReturnedJsonText := APIDownload.ResponseText
        CommitHistory := Jxon_Load(&ReturnedJsonText)

        ; Extract the time of the latest commit
        TimeRecollection := TimeToString(CommitHistory[1]["commit"]["author"]["date"])
        MacroObj.last_updated := TimeRecollection.Time " " TimeRecollection.Word " Ago"

        ; Store the full commit history (limited to the first 25 commits)
        for index, commit in CommitHistory {
            MacroObj.commit_history.Push({Time: TimeToString(commit["commit"]["author"]["date"]), Message: commit["commit"]["message"]})
        }

    } catch as E {
        OutputDebug("[DEBUG] Macro information error | " E.Message)
        MacroObj.last_updated := "[Failed to Fetch]"
    }
    MacroObj.initial_fetch_complete := true
}

AddToMacroArray(name, rawfile) {
    fileDescription := ExtractText(rawfile, "Description")
    fileVersion := ExtractText(rawfile, "Version")
    fileStatus := ExtractText(rawfile, "Status")
    
    MacroObj := {
        file: rawfile,
        name: name, 
        description: fileDescription = "" ? "" : fileDescription, 
        version: fileVersion != "" ? fileVersion : "1.0.0", 
        status: fileStatus = "" ? "Unknown" : fileStatus,
        CommitHistory: [],  ; Placeholder for commit history
        LastUpdated: "[Fetching...]",  ; Placeholder for last updated time
        InitialFetch: false
    }


    if MacroObj.status != "Hidden" {
        MacroArray.Push(MacroObj)
    }
}

stupid_reroute_function(button, index) {
    button.OnEvent("Click", (*) => MacroButtonClicked(index))
}

MainGui := Gui(Options := "+AlwaysOnTop", Title := "SOUP Macro | Version: " Version)
MainGui.BackColor := "ffffff"

MainGui_Title := MainGui.AddText("w400 h35 x0 y8 +Center", "SOUP Clan")
MainGui_Title.SetFont("s20 Bold q4", "Cascadia Code")

;MainGui_Version := MainGui.AddText("w400 h25 x0 y43 +Center", "V" Menu_Version)

; Macro List

MainGui_MacroGroupBox := MainGui.AddGroupBox("x10 y75 w170 h250")
MainGui_MacroGroupBoxTitle := MainGui.AddText("x10 y50 w170 h30 +Center", "Macro List")
MainGui_MacroGroupBoxTitle.SetFont("s16 Bold q4", "Cascadia Code")

MainGui_MacroPreviousPage := MainGui.AddButton("x40 y331 w30 h30", "<")
MainGui_MacroPreviousPage.SetFont("s16 Bold q4", "Cascadia Code")
MainGui_MacroPreviousPage.OnEvent("Click", (*) => ChangeMacroPage("Previous"))

MainGui_MacroPageNumber := MainGui.AddText("x75 y334 w40 h30 +Center", "1/1")
MainGui_MacroPageNumber.SetFont("s12 Bold q4", "Cascadia Code")

MainGui_MacroNextPage := MainGui.AddButton("x120 y331 w30 h30", ">")
MainGui_MacroNextPage.SetFont("s16 Bold q4", "Cascadia Code")
MainGui_MacroNextPage.OnEvent("Click", (*) => ChangeMacroPage("Next"))

; Macro Info

MainGui_MacroInfo_GroupBox := MainGui.AddGroupBox("x190 y75 w200 h285")

MainGui_MacroInfo_GroupBoxTitle := MainGui.AddText("x190 y50 w200 h30 +Center", "Info")
MainGui_MacroInfo_GroupBoxTitle.SetFont("s16 Bold q4", "Cascadia Code")

MainGui_MacroInfo_MacroName := MainGui.AddText("x195 y84 w190 h24 +Center", "[Name]")
MainGui_MacroInfo_MacroName.SetFont("s14 Bold q4", "Cascadia Code")
MainGui_MacroInfoArray.Push(MainGui_MacroInfo_MacroName)

MainGui_MacroInfo_MacroVersion := MainGui.AddText("x195 y108 w190 h16 +Center", "[Version]")
MainGui_MacroInfo_MacroVersion.SetFont("s8 Bold q4", "Cascadia Code")
MainGui_MacroInfoArray.Push(MainGui_MacroInfo_MacroVersion)

MainGui_MacroInfo_MacroDescription := MainGui.AddText("x195 y130 w190 h80 +Center", "[Description] `nya`nya`nya`nya")
MainGui_MacroInfo_MacroDescription.SetFont("s11 Bold q4", "Cascadia Code")
MainGui_MacroInfoArray.Push(MainGui_MacroInfo_MacroDescription)

MainGui_MacroInfo_MacroStatusLabel := MainGui.AddText("x195 y220 w190 h24 +Center", "Status")
MainGui_MacroInfo_MacroStatusLabel.SetFont("s14 Bold q4", "Cascadia Code")
MainGui_MacroInfoArray.Push(MainGui_MacroInfo_MacroStatusLabel)

MainGui_MacroInfo_MacroStatus := MainGui.AddText("x195 y245 w190 h20 +Center", "[this is a status]")
MainGui_MacroInfo_MacroStatus.SetFont("s11 Bold q4", "Cascadia Code")
MainGui_MacroInfoArray.Push(MainGui_MacroInfo_MacroStatus)

MainGui_MacroInfo_MacroLastUpdateLabel := MainGui.AddText("x195 y275 w190 h24 +Center", "Last Update")
MainGui_MacroInfo_MacroLastUpdateLabel.SetFont("s14 Bold q4", "Cascadia Code")
MainGui_MacroInfoArray.Push(MainGui_MacroInfo_MacroLastUpdateLabel)

MainGui_MacroInfo_MacroLastUpdate := MainGui.AddText("x195 y300 w190 h20 +Center", "[x days ago]")
MainGui_MacroInfo_MacroLastUpdate.SetFont("s11 Bold q4", "Cascadia Code")
MainGui_MacroInfoArray.Push(MainGui_MacroInfo_MacroLastUpdate)

MainGui_MacroInfo_RunMacro := MainGui.AddButton("x195 y330 w190 h25 +Center", "Run Macro")
MainGui_MacroInfo_RunMacro.SetFont("s12 Bold q4", "Cascadia Code")
MainGui_MacroInfo_RunMacro.OnEvent("Click", (*) => RunButtonClicked())
MainGui_MacroInfoArray.Push(MainGui_MacroInfo_RunMacro)

cachedMacros := []

/*
_InitiateHub() {
    RedrawQuickGui("Checking for updates")

    UpdatedScript := GetDependency("SOUPMacro.ahk")
    THIS_FILE := A_ScriptFullPath
    VersionCheckResults := VersionCheck(FileRead(THIS_FILE), UpdatedScript)

    if (VersionCheckResults.Changed) {
        OutputDebug("[DEBUG] FILE UPDATED | CURRENT: " VersionCheckResults.Old " | NEW: " VersionCheckResults.New)
        FileDelete(THIS_FILE)
        FileAppend(UpdatedScript, THIS_FILE, "UTF-8-RAW")
        Run(THIS_FILE)
        ExitApp
    }

    RedrawQuickGui("Initializing")

    ; check for cached macros
    Loop Files, PATH_DIR . "\SOUP_Macros\Macros\*.ahk", "F" {
        if (A_LoopFileExt = "AHK") {
            rawContents :=  FileRead(PATH_DIR . "\SOUP_Macros\Macros\" A_LoopFileName) ; FileRead(A_LoopFileFullPath) ; ReadFile(A_LoopFilePath)
            cachedMacros.Push({file: rawContents, name: dependencyName := StrSplit(A_LoopFileName, ".")[1]})
        }
    }

    MacrosFromGithub := GetFilesFromGithub(["Macros"], true)
    OutputDebug("[DEBUG] GOT GITHUB FILES")

    for filePath, rawText in MacrosFromGithub {
        ;OutputDebug("[DEBUG] GOT MACRO STUFF: " name " | " som)
        nameSplit := StrSplit(filePath, "/")
        fileNameExt := nameSplit[nameSplit.Length]
        fileName := StrSplit(fileNameExt, ".")[1]

        AddToMacroArray(fileName, rawText)
    }

    for _, macroObject in cachedMacros {
        ;MacroArray.Push(macroObject)
    }

    Loop MacroButtonAmount {
        if (A_Index = 1) {
            ;continue
        }
        newButton := MainGui.AddButton("x15 y" 85 + (A_Index * 30) - 30 " w160 h26", "")
        newButton.SetFont("s11", "Cascadia Code")
    
        if (cachedMacros.Has(A_Index)) {
            newButton.Visible := true
            newButton.Text := cachedMacros[A_Index].name
    
        } else {
            newButton.Visible := false
            newButton.Text := "none"
        }
    
        stupid_reroute_function(newButton, A_Index)
        MainGui_MacroButtonArray.Push(newButton)
    }

    for i, _Array in [MainGui_MacroInfoArray] {
        for j, Item in _Array {
            Item.Visible := false
        }
    }

    UpdateMacroPage()

    CreateFolders(PATH_DIR, FOLDER_TREE)
    QuickGui.Hide()
    MainGui.Show("w400 h370")
}

_InitiateHub()*/

CreateMacroObject(argMap) {
    global MacroArray

    newObj := {
        name: argMap.HasOwnProp("name") ? argMap.name : "UNKNOWN",
        description: argMap.HasOwnProp("description") ? argMap.description : "",
        version: argMap.HasOwnProp("version") ? argMap.version : "1.0.0",
        status: argMap.HasOwnProp("status") ? argMap.status : "Unknown",

        file_name: argMap.HasOwnProp("filename") ? argMap.filename : "",
        path:argMap.HasOwnProp("path") ? argMap.path : "",

        commit_history: [],
        last_updated: "?",
        initial_fetch_complete: false
    }

    if argMap.HasOwnProp("download_url") {
        newObj.download_url := argMap.download_url
    }

    if argMap.HasOwnProp("local_path") {
        newObj.local_path := argMap.local_path
        newObj.local_version := argMap.local_version
        newObj.raw_file := argMap.raw_file
    }

    if argMap.HasOwnProp("is_custom") {
        newObj.is_custom := argMap.is_custom
    }

    MacroArray.Push(newObj)
}

GetMacrosFromGithub() {
    raw := GetRawFromURL(GITHUB_API_URL . "Macros")
    json_response := Jxon_Load(&raw)

    if (!json_response || !IsObject(json_response)) {
        MsgBox("Failed to load from JSON")
    }

    FileMap := Map()

    for _, file in json_response {
        if IsObject(file) && file.has("type") {
            if file["type"] = "file" {
                FileMap[file["name"]] := {
                    name: file["name"],
                    path: file["path"],
                    download_url: file["download_url"]
                }
            }
        }
    }

    return FileMap
}

GetMacroInformation() {
    global LocalMacros

    GithubMacros := GetMacrosFromGithub()

    HTTPRequest := ComObject("WinHttp.WinHttpRequest.5.1")
    HTTPRequest.Open("GET", "https://raw.githubusercontent.com/ur-lucky/SOUP_Macros/main/MacroInformation.json", true)
    HTTPRequest.Send()
    HTTPRequest.WaitForResponse()
    response := HTTPRequest.ResponseText
    
    Request_JSON := Jxon_Load(&response)

    for mapName, mapObj in Request_JSON {
        if mapName = "Macros" {
            for key, config in mapObj {
                if GithubMacros.Has(key) {
                    GitubMacroInfo := GithubMacros[key]
        
                    newArgMap := {}
                    
                    
                    newArgMap.description := config.Has("description") ? config["description"] : ""
                    newArgMap.status := config.Has("status") ? config["status"] : "Unknown"
                    newArgMap.version := config.Has("version") ? config["version"] : "1.0.0"


                    MsgBox("found description " newArgMap.description)
                    
                    if LocalMacros.Has(key) {
                        LocalMacro := LocalMacros[key]
                        newArgMap.name := LocalMacro.name
                        newArgMap.local_version := LocalMacro.version
                        newArgMap.filename := LocalMacro.filename
                        newArgMap.local_path := LocalMacro.path
                        newArgMap.raw_file := LocalMacro.raw_file
                    } else {
                        newArgMap.name := config.Has("name") ? config["name"] : key
                        newArgMap.filename := GitubMacroInfo.name
                    }
                    
                    newArgMap.path := GitubMacroInfo.path
                    newArgMap.download_url := GitubMacroInfo.download_url
                    
        
                    CreateMacroObject(newArgMap)
                } else {
                    MsgBox("couldnt find " key)
                }
            }
        } else if mapName = "Hub" {
            HTTPRequest := ComObject("WinHttp.WinHttpRequest.5.1")
            HTTPRequest.Open("GET", "https://raw.githubusercontent.com/ur-lucky/SOUP_Macros/main/SOUPMacro.ahk", true)
            HTTPRequest.Send()
            HTTPRequest.WaitForResponse()

            UpdatedFile := HTTPRequest.ResponseText
            THIS_FILE := A_ScriptFullPath
            VersionCheckResults := VersionCheck(FileRead(THIS_FILE), UpdatedFile)
        
            if (VersionCheckResults.Changed) {
                FileDelete(THIS_FILE)
                FileAppend(UpdatedFile, THIS_FILE, "UTF-8-RAW")
                Run(THIS_FILE)
                ExitApp
            }
        }
    }
}

GetLocalMacros() {
    global LocalMacros
    
    Loop Files, A_MyDocuments . "\SOUP_Macros\Macros\*.ahk", "F" {
        if (A_LoopFileExt = "AHK") {
            rawContents :=  FileRead(A_MyDocuments . "\SOUP_Macros\Macros\" A_LoopFileName) ; FileRead(A_LoopFileFullPath) ; ReadFile(A_LoopFilePath)
            CurrentVersion := ExtractText(rawContents, "Version")
            
            filePath := A_MyDocuments . "\SOUP_Macros\Macros\" A_LoopFileName

            newArgMap := {
                name: StrSplit(A_LoopFileName, ".")[1],
                version: CurrentVersion,
                filename: A_LoopFileName,
                path: filePath,
                raw_file: FileRead(filePath)
            }
            
            

            LocalMacros[A_LoopFileName] := newArgMap
        }
    }
}

CreateFolders(PATH_DIR, FOLDER_TREE)
GetLocalMacros()
GetMacroInformation()

Loop MacroButtonAmount {
    if (A_Index = 1) {
        ;continue
    }
    newButton := MainGui.AddButton("x15 y" 85 + (A_Index * 30) - 30 " w160 h26", "")
    newButton.SetFont("s11", "Cascadia Code")

    if (MacroArray.Has(A_Index)) {
        newButton.Visible := true
        newButton.Text := MacroArray[A_Index].name

    } else {
        newButton.Visible := false
        newButton.Text := "none"
    }

    stupid_reroute_function(newButton, A_Index)
    MainGui_MacroButtonArray.Push(newButton)
}

for i, _Array in [MainGui_MacroInfoArray] {
    for j, Item in _Array {
        Item.Visible := false
    }
}

UpdateMacroPage()

QuickGui.Hide()
MainGui.Show("w400 h370 xCenter y200")
;VersionTest := GetDependency("Macros\VersionTest.ahk")
;ProcessDependencies("Macros\VersionTest.ahk")


F8::ExitApp


; this is just a temporary file :)