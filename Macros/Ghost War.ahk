#Requires AutoHotkey v2.0
#SingleInstance Force

global MacroName := "Ghost Clan War"
global MacroDescription := "Automatically position character"
global MacroStatus := "Unstable"

global Version := "1.0.0"
global Dependencies := [
    "Utils\UWBOCRLib.ahk","Utils\Functions.ahk","Utils\PS99Functions.ahk","Storage\PS99UI.ahk",
    "Modules\UseItem.ahk", "Modules\Autofarm.ahk","Modules\MoveHumanoid.ahk","Modules\Reconnect.ahk","Modules\TeleportToWorld.ahk","Modules\TeleportToZone.ahk", "Modules\ValidateClan.ahk"
]

#Include "%A_MyDocuments%\SOUP_Macros\Utils\UWBOCRLib.ahk"
#Include "%A_MyDocuments%\SOUP_Macros\Utils\Functions.ahk"
#Include "%A_MyDocuments%\SOUP_Macros\Utils\PS99Functions.ahk"
#Include "%A_MyDocuments%\SOUP_Macros\Storage\PS99UI.ahk"

#Include "%A_MyDocuments%\SOUP_Macros\Modules\Autofarm.ahk"
#Include "%A_MyDocuments%\SOUP_Macros\Modules\MoveHumanoid.ahk"
#Include "%A_MyDocuments%\SOUP_Macros\Modules\Reconnect.ahk"
#Include "%A_MyDocuments%\SOUP_Macros\Modules\TeleportToWorld.ahk"
#Include "%A_MyDocuments%\SOUP_Macros\Modules\TeleportToZone.ahk"
#Include "%A_MyDocuments%\SOUP_Macros\Modules\UseItem.ahk"
#Include "%A_MyDocuments%\SOUP_Macros\Modules\ValidateClan.ahk"

CoordMode "Pixel", "Client"
CoordMode "Mouse", "Client"
SetMouseDelay -1

global isRunning := false
global OnlyUltra := false
global ClickCoordinatesPolygon := [{X: 190, Y: 56}, {X: 605, Y: 56}, {X: 605, Y: 200}, {X: 190, Y: 200}]
global MovementMap := Map()
global focusDebounce := 250  ; 250ms debounce time for window focus checks
global mountedGuis := []
global windows := []  ; Array to hold data for each window

MovementMap["SpawnToEvent"] := [
    {Key: "Q"},
    {Rest: 100},
    {Key: "A", Duration: 500},
    {Rest: 600},
    {Key: "S", Duration: 2000},
    {Rest: 2100},
    {Key: "Q"},
]

MovementMap["FirstArea"] := [
    {Key: "Q"},
    {Rest: 100},
    {Key: "W", Duration: 800},
    ;{Key: "W", Action: "Down", Duration: 500},
    {Rest: 800},
    {Func: EnableAutofarm},
]

MovementMap["SecondArea"] := [
    {Key: "S", Duration: 2000},
    {Rest: 2000},
    {Key: "Q"},
]


CheckNotification() {
    global OnlyUltra
    if UIPixelSearch("Notification_Close") {
        if UIPixelSearch("Notification_Oops") {
            ; has blue bar on top
            ; could be out of cubes or only able to use 1 kind
            foundText := SearchNotificationWarningText()
            if RegExMatch(foundText, "Use|use") > 0 {
                ; choose the left side (Pet Cube)
                if OnlyUltra = true {
                    return "Notification_No"
                }
                return "Notification_Yes"
            } else if RegExMatch(foundText, "catch|these|need") > 0 {
                ; choose the left side (Pet Cube)
                return "Notification_Ok"
            }
        } else {
            ; is asking a question
            ; most likely asking which pet cube to use
            foundText := SearchNotificationQuestion()
            if RegExMatch(foundText, "Which|which|catch") > 0 {
                ; choose the left side (Pet Cube)
                if OnlyUltra = true {
                    return "Notification_No"
                }
                return "Notification_Yes"
            }
        }
        return "Notification_Close"
    }
    return false
}

_IsInEvent() {
    local isInEvent := false
    Loop {
        if !UIPixelSearchLoop("HUD_Teleport_Button_Red", "HUD_Teleport_Button_Red")[1] {
            ExitMenus()
            Debug("COULDN'T FIND TELEPORT BUTTON")
            continue
        }
        Sleep(200)
        UIClick("HUD_Teleport_Button")
        Sleep(400)
        if !PixelSearch(&outX, &outY, 63, 104, 70, 112, 0xDB113F, 25) {
            Debug("NOT IN MENU?")
            continue
        } else {
            if !UIPixelSearch("Teleport_World2", "Teleport_World2")[1] {
                isInEvent := true
            }
            break
        }
    }
    Debug("IS IN EVENT MENU: " isInEvent)

    return isInEvent
}

ResetCharacter() {
    Loop {
        if _IsInEvent() {
            UIClick("Zone1", 6)
            Sleep(300)
            if (_FindOops()) {
                ExitMenus()
                Sleep(300)
                _IsInEvent()
                UIClick("Zone5", 6)
                Sleep(4500)
                continue
            } else {
                Debug("TELEPORTING TO ZONE 1?")
                Sleep(4500)
            }
            SolveMovement([{Key: "S", Duration: 1000},])
        }
            
        TeleportToWorld("Teleport_World1")
        TeleportToWorld("Teleport_World3")

        if not ValidateClan() {
            continue
        }

        TeleportToZone("Prison Tower")
        TeleportToZone("_Spawn")

        SolveMovement(MovementMap["SpawnToEvent"])

        if !UIPixelSearchLoop("HUD_Teleport_Button_Red", "HUD_Teleport_Button_Red", 20000)[1] {
            continue
        }

        if _IsInEvent() {
            UIClick("Zone5", 3)
            Sleep(4500)
            SolveMovement(MovementMap["FirstArea"])
            Sleep(300)
            UseItem("Hasty Flag", 40, 50)
            Sleep(300)
            SolveMovement(MovementMap["SecondArea"])
        }
        break
    }
}

UpdateGuiPositions() {
    global mountedGuis, focusDebounce

    for mountedGui in mountedGuis {
        ; Find the associated window for the current GUI
        associatedWindow := false
        for window in windows {
            if window.Hwnd = mountedGui.Hwnd {
                associatedWindow := window
                break
            }
        }

        if WinActive("ahk_class AutoHotkeyGUI") {
            continue
        }

        ; Check if the window is active and not running
        if WinActive("ahk_id " mountedGui.Hwnd) && not associatedWindow.IsRunning {
            ; Debounce logic: Ensure the window has been active for at least focusDebounce ms
            if (!associatedWindow.LastFocusTime || (A_TickCount - associatedWindow.LastFocusTime) >= focusDebounce) {
                if not mountedGui.Visibility {  ; Show the GUI only if it's currently hidden
                    mountedGui.Gui.Show()
                    mountedGui.Visibility := true
                }

                newX := mountedGui.RelX
                newY := mountedGui.RelY
                mountedGui.Gui.Move(newX, newY)
            }
        } else {
            ; Hide the GUI only if it's currently visible
            if mountedGui.Visibility {
                mountedGui.Gui.Hide()
                mountedGui.Visibility := false
            }

            ; If window becomes active, record the activation time
            if WinActive("ahk_id " mountedGui.Hwnd) {
                associatedWindow.LastFocusTime := A_TickCount
            }
        }
    }
}

mountGuiToWindow(hwnd, guis) {
    ; Get initial window position
    WinGetPos(&windowX, &windowY,,, "ahk_id " hwnd)

    ; For each GUI, calculate its relative position to the window's current position
    for gui in guis {
        ; Get the GUI's current position
        gui.Opt("+Parent" hwnd)
        guiPos := gui.GetPos(&X, &Y)
        relX := X - windowX
        relY := Y - windowY - 31
        mountedGuis.Push({Gui: gui, RelX: relX, RelY: relY, Hwnd: hwnd, Visibility: true})
    }

    ; Start a timer to continuously track the window's position and update the GUIs
    SetTimer(UpdateGuiPositions, 50)
}

CleanOldTimestamps(window) {
    currentTime := A_TickCount
    newTimestamps := []

    for timestamp in window.CatchTimestamps {
        if (currentTime - timestamp <= 120000) {  ; Keep timestamps within 120 seconds
            newTimestamps.Push(timestamp)
        }
    }
    
    return newTimestamps
}

; Initialize windows and mount GUIs
global initialized := false
for hwnd in WinGetList("ahk_exe RobloxPlayerBeta.exe") {
    pid := WinGetPID("ahk_id" hwnd)

    ; Activate and move the window
    WinActivate("ahk_id" hwnd)
    WinMove(,,816, 638, "ahk_id" hwnd)
    WinWaitActive("ahk_id" hwnd)
    WinGetPos(&windowX, &windowY, &windowWidth, &windowHeight, "ahk_id " hwnd)

    ; Draw and mount GUI for this window
    guis := DrawPolygon(ClickCoordinatesPolygon, 0, "ff0000", 2, true)
    mountGuiToWindow(hwnd, guis)



    runningGui := Gui()
    runningGui.Opt("+LastFound +AlwaysOnTop -Caption +ToolWindow +Parent" . hwnd)
    runningGui.BackColor := "FFFFFF"
    WinSetTransColor("FFFFFF 255", runningGui)
    runningGui.SetFont("c0x000000 s18 w600")
    infoText := runningGui.AddText("w600 h300 Center", "")
    
    runningGui.Show("y-5") ; . windowHeight/2 + 100)

    ; Add this window's data to the array, including LastFocusTime
    windows.Push({
        Hwnd: hwnd, 
        LastChestCheckTick: A_TickCount,
        LastCatchPrompt: A_TickCount,
        LastPetCaught: A_TickCount,
        CurrentSessionStartTick: A_TickCount,
        LastTimestampClean: A_TickCount,
        LastAntiAFK: A_TickCount,
        OutOfCubesTick: 0,
        LastFocusTime: 0,
        CatchTimestamps: [],
        IsRunning: false,
        IsPositioned: false,
        CatchAttempts: 0,
        WorldRejoins: -1,
        GuiText: infoText
    })
}


one_hour := 60 * 60 * 1000

MsgBox("F3 to start`nF5 to pause`nF8 to exit`n`ndont touch anything once you start")


; Main Loop
Loop {
    for index, window in windows {
        if !WinExist("ahk_id " window.Hwnd) {
            windows.RemoveAt(index)
            continue
        }
        global OnlyUltra
        window.GuiText.Text := (window.IsRunning ? "Running" : "Not Running") . " | Rejoins: " . (window.WorldRejoins > 0 ? window.WorldRejoins : "0")

        if window.IsRunning {
            WinActivate("ahk_id" window.Hwnd)
            WinWaitActive("ahk_id" window.Hwnd)
    
            if !window.IsPositioned {
                ResetCharacter()
                window.IsPositioned := true
                window.CurrentSessionStartTick := A_TickCount
                window.LastCatchPrompt := A_TickCount
                window.LastPetCaught := A_TickCount
                window.OutOfCubesTick := 0
                window.WorldRejoins += 1
                for _, owindow in windows {
                    owindow.LastCatchPrompt := A_TickCount
                }
            }
            ; Activate the window

            if (A_TickCount - window.LastAntiAFK >= 300000) {
                Loop 5 {
                    SendEvent("{Click 2 2}")
                    Sleep(10)
                }
                window.LastAntiAFK := A_TickCount
            }

            if (A_TickCount - window.LastChestCheckTick > 1000) {
                SendEvent("{R Down}{R Up}")
                window.LastChestCheckTick := A_TickCount
            }

            if (A_TickCount - window.CurrentSessionStartTick > (one_hour * 2)) {
                ; escape loop to "rejoin"
                window.IsPositioned := false
                continue
            }
        }
    }
    Sleep(10)
}

ToggleState(state := "") {
    global windows
    global initialized
    if !initialized {
        initialized := true
    }

    for window in windows {
        if not state {
            state := !window.IsRunning
        }
        window.IsRunning := state
        window.CurrentSessionStartTick := A_TickCount
        window.LastCatchPrompt := A_TickCount
    }
}


^F1::{
    global initialized
    if initialized {
        return
    }

    global windows
    for window in windows {
        window.SensitivitySet := true
        window.IsPositioned := true
        window.CurrentSessionStartTick := A_TickCount
    }
    ToggleState(true)
}

F3:: {
    ToggleState(true)
}

F5:: {
    ToggleState()
}

^F2::{
    global OnlyUltra
    OnlyUltra := !OnlyUltra
}


F8::ExitApp()  ; Exit the application