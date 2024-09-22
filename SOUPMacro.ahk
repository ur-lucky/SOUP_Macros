#Requires AutoHotkey v2.0
#SingleInstance Force

global Version := "1"

global PATH_DIR := A_MyDocuments
global FOLDER_TREE := {
    SOUP_Macros: {
        Macros: [],
        Modules: [],
        Utils: []
    }
}

global GITHUB_API_URL := "https://api.github.com/repos/ur-lucky/SOUP_Macros/contents/"  ; GitHub API URL for your folder
global GITHUB_RAW_URL := "https://raw.githubusercontent.com/ur-lucky/SOUP_Macros/main/" ; Raw URL to fetch files
global ProcessedDependencies := []

global ColorMap := Map()
ColorMap["Stable"] := "0x00ff4c"
ColorMap["Unstable"] := "0xdd0000"

QuickGui := Gui(Options := "+AlwaysOnTop -Caption -SysMenu", Title := "Preload")
QuickGui.SetFont("s15 w450 q2")
QuickGuiText := QuickGui.AddText("Center w450")

RedrawQuickGui(NewText := "text", Duration := 0) {
    QuickGuiText.Text := NewText
    QuickGuiText.Redraw()
    QuickGui.Show()

    if (Duration != 0) {
        SetTimer(QuickGui.Hide(), -Duration)
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

GetRawFromURL(url) {
    OutputDebug("[DEBUG] | MAKING A REQUEST")
    retries := 3  ; Number of retries
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
                MsgBox "API rate limit exceeded. Retrying..."
                Sleep(10000)  ; Wait 10 seconds before retrying (can be longer)
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



GetDependency(dependencyString) {
    urlPath := GITHUB_RAW_URL . StrReplace(dependencyString, "\", "/")  ; Use "/" for GitHub API paths
    raw := GetRawFromURL(urlPath)
    return raw
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




;global UtilsMap := GetFilesFromGithub(["Utils"])
;global ModulesMap := GetFilesFromGithub(["Modules"])
;global MacrosMap := GetFilesFromGithub(["Macros"], true)

;global FileMap := GetFilesFromGithub([])

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

HubGui := Gui(Options := "", Title := "SOUP Macro")
HubGui.BackColor := "ffffff"


HubTitle := HubGui.AddText("x5 y6 w300 h40 +Center", "SOUP Macro")
HubTitle.SetFont("s25 Bold q3 c000000", "Comic Sans MS")

;Hub_MacroGroupBoxTitle := HubGui.AddText("x10 y60 w150 h20 +Center", "Macro")
Hub_MacroGroupBox := HubGui.AddGroupBox("x10 y85 w150 h200 +Center ", "Macro")


_init() {
    RedrawQuickGui("Checking for updates")

    UpdatedScript := GetDependency("SOUPMacro.ahk")

    THIS_FILE := A_ScriptFullPath
    VersionCheckResults := VersionCheck(THIS_FILE, UpdatedScript)

    
    if (VersionCheckResults.Changed) {
        OutputDebug("[DEBUG] FILE UPDATED | CURRENT: " VersionCheckResults.Old " | NEW: " VersionCheckResults.New)
        FileDelete(THIS_FILE)
        FileAppend(UpdatedScript, THIS_FILE, "UTF-8-RAW")
        Run(THIS_FILE)
        ExitApp
    }

    RedrawQuickGui("Initializing")
    CreateFolders(PATH_DIR, FOLDER_TREE)

    GetDependency("")

    QuickGui.Hide()
    HubGui.Show()
}

_init()

F8::ExitApp()

;VersionTest := GetDependency("Macros\VersionTest.ahk")
;ProcessDependencies("Macros\VersionTest.ahk")