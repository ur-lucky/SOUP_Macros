#Requires AutoHotkey v2.0
#SingleInstance Force

major_version := 0
minor_version := 0
patch_version := 0
label := "alpha"

MacroButtonAmount := 8

global PATH_DIR := A_MyDocuments
global FOLDER_TREE := {
    SOUP_Macros: {
        Macros: [],
        Modules: [],
        Utils: []
    }
}

global Menu_Version := major_version "." minor_version "." patch_version (label != "" ? "-" label : "")
global GITHUB_API_URL := "https://api.github.com/repos/ur-lucky/SOUP_Macros/contents/"
global GITHUB_RAW_URL := "https://raw.githubusercontent.com/ur-lucky/SOUP_Macros/main/"


global CurrentPage := 1
global PageWhenButtonClicked := 1
global MacroButtonSelected := 1
global MainGui_MacroButtonArray := []
global MainGui_MacroInfoArray := []
global MacroArray := []
global ProcessedDependencies := []


QuickGui := Gui(Options := "+AlwaysOnTop -Caption -SysMenu", Title := "Preload")
QuickGui.SetFont("s15 w450 q2")
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

ProcessDependencies(dependencyPath) {
    ; Prevent infinite loops with already processed dependencies
    if ProcessedDependencies.Has(dependencyPath) {
        return
    }
    
    ProcessedDependencies.Push(dependencyPath)

    rawDependency := GetDependency(dependencyPath)
    dependencies := DependencyCheck(rawDependency)
    
    dependencySplit := StrSplit(dependencyPath, "\")
    dependencyFileName := dependencySplit[dependencySplit.Length]
    dependencyName := StrSplit(dependencyFileName, ".")[1]
    localPath := PATH_DIR . "\SOUP_Macros\" . dependencyPath

    ; Check if the file already exists
    if FileExist(localPath) {
        VersionCheckResults := VersionCheck(FileRead(localPath), rawDependency)
        if (VersionCheckResults.Changed) {
            switch MsgBox(
                "Dependency `"" dependencyName "`" was updated `nWould you like to update?`nCurrent: " VersionCheckResults.Old "`nNew: " VersionCheckResults.New,
                "SOUP Macros", 
                "0x1032 0x4"
            ) {
                case "Yes":
                    FileDelete(localPath)
                    FileAppend(rawDependency, localPath, "UTF-8-RAW")
                    MsgBox("Updated and running the macro")
                default:
                    MsgBox("Running the current version")
            }
        }
    } else {
        switch MsgBox(
            "Dependency `"" dependencyName "`" is missing.`nWould you like to install it?", 
            "SOUP Macros", 
            "0x1032 0x4"
        ) {
            case "Yes":
                FileAppend(rawDependency, localPath, "UTF-8-RAW")
        }
    }

    ; Output debug information about the current dependency
    OutputDebug("[DEPENDENCY] DETECTED | " dependencyName)

    ; Recursively process each dependency of this dependency
    for subDependencyPath in dependencies {
        ProcessDependencies(subDependencyPath)
    }
}

CreateFolders(BasePath, FolderTree) {
    for folder, subFolders in FolderTree.OwnProps() {
        fullPath := BasePath "\" folder
        DirCreate(fullPath)
        ; Recursively create subfolders
        if IsObject(subFolders) {
            CreateFolders(fullPath, subFolders)
        }
    }
}

; UI Functions

UpdateMacroPage() {
    global CurrentPage
    global MacroArray

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
    MainGui_MacroPageNumber.Text := CurrentPage . "/" . MaxPages
}

ChangeMacroPage(Index := "Next") {
    global CurrentPage
    global MacroArray

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

MacroButtonClicked(buttonNumber) {
    global CurrentPage
    global PageWhenButtonClicked
    global MacroButtonSelected

    if (CurrentPage = PageWhenButtonClicked) and (MacroButtonSelected = buttonNumber) {
        return ; user clicked on the same button
    }

    PageWhenButtonClicked := CurrentPage
    MacroButtonSelected := buttonNumber

    MacroIndex := (CurrentPage * MacroButtonAmount) - MacroButtonAmount + buttonNumber

    macroObj := MacroArray.Get(MacroIndex)

    MainGui_MacroInfo_MacroName.Text := macroObj.name
    MainGui_MacroInfo_MacroVersion.Text := macroObj.version
    MainGui_MacroInfo_MacroDescription.Text := macroObj.description
    MainGui_MacroInfo_MacroStatusLabel.Text := macroObj.status

 
}


MainGui := Gui(Options := "+AlwaysOnTop", Title := "SOUP Macro | Version: " Menu_Version)
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


cachedMacros := []


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

    for _, macroObject in cachedMacros {
        ;MacroArray.Push(macroObject)
    }

    Loop MacroButtonAmount {
        if (A_Index = 1) {
            ;continue
        }
        newButton := MainGui.AddButton("x15 y" 85 + (A_Index * 30) - 30 " w160 h25", "")
        newButton.SetFont("s11", "Cascadia Code")
    
        if (cachedMacros.Has(A_Index)) {
            newButton.Visible := true
            newButton.Text := cachedMacros[A_Index].name
    
        } else {
            newButton.Visible := false
            newButton.Text := "none"
        }
    
        newButton.OnEvent("Click", (*) => MacroButtonClicked(A_Index))
    
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

_InitiateHub()

F8::ExitApp

;VersionTest := GetDependency("Macros\VersionTest.ahk")
;ProcessDependencies("Macros\VersionTest.ahk")