#Requires AutoHotkey v2.0
#SingleInstance Force

global MacroName := "Pet Cube"
global MacroDescription := "Automatically break boss chest and capture pets"
global MacroStatus := "Stable"

global Version := "1.0.0f"
global Dependencies := [
    "Utils\UWBOCRLib.ahk","Utils\Functions.ahk","Utils\PS99Functions.ahk","Storage\PS99UI.ahk",
    "Modules\Autofarm.ahk","Modules\MoveHumanoid.ahk","Modules\Reconnect.ahk","Modules\TeleportToWorld.ahk","Modules\TeleportToZone.ahk", "Modules\ValidateClan.ahk"
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
#Include "%A_MyDocuments%\SOUP_Macros\Modules\ValidateClan.ahk"

CoordMode "Pixel", "Client"
CoordMode "Mouse", "Client"
SetMouseDelay -1

global isRunning := false
global ClickCoordinatesPolygon := [{X: 190, Y: 56}, {X: 605, Y: 56}, {X: 605, Y: 200}, {X: 190, Y: 200}]
global MovementMap := Map()
global focusDebounce := 250  ; 250ms debounce time for window focus checks
global mountedGuis := []
global windows := []  ; Array to hold data for each window

global colorsToSearch := [
    {color: "0x6268C5", variation: 60},
    {color: "0x314AB6", variation: 60},
    {color: "0xFB6408", variation: 60},
    {color: "0xfbd608", variation: 60},
    {color: "0XFFFF32", variation: 60},
    {color: "0xbd34eb", variation: 60},
    {color: "0xDC74FF", variation: 60},
    {color: "0x2D4B54", variation: 60},
    {color: "0X445A46", variation: 60},
]

MovementMap["PositionCamera"] := [
    {Key:"Camera", Direction: "X", Degrees: 90},
    {Key:"Camera", Direction: "Y", Degrees: 90},
    {Key: "WheelDown", Repeat: 15, Delay: 100}
    {Rest: 1000}
    {Key: "WheelDown", Repeat: 5, Delay: 100}
]

MovementMap["CatchingArea"] := [
    {Key: "Q"},
    {Rest: 100},
    {Key: "W", Duration: 1375},
    {Rest: 800},
    {Func: EnableAutofarm},
    {Rest: 500},
    {Key: "Q"},

]

MovementMap["BossChest"] := [
    {Key: "Q"},
    {Rest: 100},
    {Key: "W", Duration: 880},
    {Rest: 880},
    {Key: "D", Duration: 1100},
    {Rest: 1100},
    {Key: "Q"},
]


MovementMap["ResetTest"] := [
    ;{Key:"Camera", Direction: "X", Degrees: -90},
]

MovementMap["CatchPetsEvent"] := [
    {Key:"Camera", Direction: "X", Degrees: 90},
    {Key: "Q"},
    {Rest: 100},
    {Key: "D", Duration: 1000},
    ;{Key: "W", Action: "Down", Duration: 500},
    {Rest: 1200},
    {Func: EnableAutofarm},
    {Key: "S", Duration: 300},
    {Rest: 1000},
    {Key: "Q"},
    {Key: "WheelDown", Repeat: 15, Delay: 200}
]


IsPointInsidePolygon(PointX, PointY, VerticesArray) {
    crossings := 0
    for i, vertex1 in VerticesArray {
        vertex2 := (i = VerticesArray.Length) ? VerticesArray[1] : VerticesArray[i+1]
        if (vertex1.Y <= PointY and vertex2.Y > PointY) or (vertex1.Y > PointY and vertex2.Y <= PointY) {
            slope := (PointY - vertex1.Y) / (vertex2.Y - vertex1.Y)
            intersectX := vertex1.X + slope * (vertex2.X - vertex1.X)
            if PointX < intersectX
                crossings++
        }
    }
    return Mod(crossings, 2) ; Returns true if the point is inside the polygon
}

IsBossChestCorrupted() {
    return PixelSearch(&outX, &outY, 735, 447, 785, 465, "0x252525", 20)
}

IsBossChestAlive() {
    return not PixelSearch(&outX, &outY, 718, 452, 781, 461, "0x765848", 10)
}


CustomPixelSearch(color, variation) {
    foundPixel := PixelSearch(&foundX, &foundY, ClickCoordinatesPolygon[1].X, ClickCoordinatesPolygon[1].Y, ClickCoordinatesPolygon[3].X, ClickCoordinatesPolygon[3].Y, color, variation)
    if foundPixel {
        if UIPixelSearch("Notification_Close", "Exit")[1] {
            UIClick("Notification_Yes")
            Sleep(10)
            return true
        } else {
            SendEvent("{Click " foundX " " foundY " 1}")
            if UIPixelSearch("Notification_Close", "Exit")[1] {
                UIClick("Notification_Yes")
                return true
            }
        }
    }
    return false
}

CheckNotification() {
    if UIPixelSearch("Notification_Close") {
        if UIPixelSearch("Notification_Oops") {
            ; has blue bar on top
            ; could be out of cubes or only able to use 1 kind
            foundText := SearchNotificationWarningText()
            if RegExMatch(foundText, "Use|use") > 0 {
                ; choose the left side (Pet Cube)
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
                return "Notification_Yes"
            }
        }
        return "Notification_Close"
    }
    return false
}

DoBossChest() {
    Debug("TELEPORTING ELEMENTAL REALM - BOSS CHEST FUNC")
    TeleportToZone("Elemental Realm")
    SolveMovement(MovementMap["BossChest"])
    Sleep(20)
    SendEvent("{R Down}{R Up}")
    Sleep(200)
    TeleportToZone("Elemental Realm")
    SolveMovement(MovementMap["CatchingArea"])
}

ResetCharacter() {
    Loop {
        TeleportToWorld("Teleport_World1")
        TeleportToWorld("Teleport_World3")

        if not ValidateClan() {
            continue
        }

        TeleportToZone("Elemental Realm", 10000)
        Sleep(500)
        SolveMovement(MovementMap["PositionCamera"])
        SolveMovement(MovementMap["CatchingArea"])

        break
    }
}

CustomPixelSearchAndHandlePets(window) {
    global ClickCoordinatesPolygon
    global colorsToSearch

    CoordMode "Pixel", "Client"
    CoordMode "Mouse", "Client"

    ; Calculate the total height and split into 3 sections
    height := ClickCoordinatesPolygon[3].Y - ClickCoordinatesPolygon[1].Y
    splitY := height / 3

    ; Loop through each of the 3 Y sections
    Loop 3 {
        y1 := ClickCoordinatesPolygon[3].Y - (splitY * (A_Index - 1))  ; Start Y of the current section
        y2 := y1 - splitY  ; End Y of the current section

        ;DrawPolygon([{X: ClickCoordinatesPolygon[1].X, Y: y1}, {X: ClickCoordinatesPolygon[2].X, Y: y1}, {X: ClickCoordinatesPolygon[3].X, Y: y2}, {X: ClickCoordinatesPolygon[4].X, Y: y2}], 1000, "ff0000", 2, true)
        
        ; Loop through each color in the list
        for colorData in colorsToSearch {
            foundPixel := PixelSearch(&foundX, &foundY, ClickCoordinatesPolygon[1].X, y1, ClickCoordinatesPolygon[3].X, y2, colorData.color, colorData.variation)
            if foundPixel {
                ; Click the found pixel
                SendEvent("{Click " foundX " " foundY " 1}")
                ; Check for notification and handle it
                if UIPixelSearchLoop("Notification_Close", "Exit", 0)[1] {
                    buttonToClick := CheckNotification()
                    Debug("BUTTON TO CLICK: " buttonToClick)
                    if buttonToClick {
                        if buttonToClick = "Notification_Yes" {
                            UIClick(buttonToClick)
                            window.LastPetCaught := A_TickCount
                            return true
                        } else if buttonToClick = "Notification_Ok" {
                            UIClick(buttonToClick)
                            window.OutOfCubesTick := A_TickCount
                            return true
                        } else {
                            UIClick(buttonToClick)
                            return true
                        }
                    }
                }
            }
        }
    }
    return false
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

; Initialize windows and mount GUIs
global initialized := false
for hwnd in WinGetList("ahk_exe RobloxPlayerBeta.exe") {
    pid := WinGetPID("ahk_id" hwnd)

    ; Activate and move the window
    WinActivate("ahk_id" hwnd)
    WinMove(,,816, 638, "ahk_id" hwnd)
    WinWaitActive("ahk_id" hwnd)

    ; Draw and mount GUI for this window
    guis := DrawPolygon(ClickCoordinatesPolygon, 0, "ff0000", 2, true)
    mountGuiToWindow(hwnd, guis)

    ; Add this window's data to the array, including LastFocusTime
    windows.Push({
        Hwnd: hwnd, 
        LastChestCheckTick: A_TickCount,
        LastCatchPrompt: A_TickCount,
        LastPetCaught: A_TickCount,
        CurrentSessionStartTick: A_TickCount,
        SensitivitySet: false,
        OutOfCubesTick: 0,
        IsRunning: false,
        IsPositioned: false,
        LastFocusTime: 0  ; Initialize LastFocusTime
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

        if window.IsRunning {
            WinActivate("ahk_id" window.Hwnd)
            WinWaitActive("ahk_id" window.Hwnd)

            if !window.SensitivitySet {
                SetCameraSensitivity()
                window.SensitivitySet := true
            }
    
            if !window.IsPositioned {
                ResetCharacter()
                window.IsPositioned := true
                window.CurrentSessionStartTick := A_TickCount
            }
            ; Activate the window


            if (A_TickCount - window.CurrentSessionStartTick > (one_hour * 2)) {
                ; escape loop to "rejoin"
                window.IsPositioned := false
                continue
            }
            
            if (A_TickCount - window.LastCatchPrompt >= 300000) {
                window.IsPositioned := false
                continue
            }

            if (A_TickCount - window.LastPetCaught <= 2000) {
                continue
            }

            if (A_TickCount - window.OutOfCubesTick <= 60000) {
                continue
            }

            ; Check for boss chest every 1000 ms
            if (A_TickCount - window.LastChestCheckTick > 1000) {
                ;DrawPolygonOnUI("Ultimate_Check", 1000)
                ;SuccessfulUltiCheck := UIPixelSearch("Ultimate_Check", "Ultimate_Blue")[1]
                ;SuccessfulUtliCheck2 := PixelSearch(&QIOQDHQOI, &doiqbdwoiqb, 267, 477, 280, 492, "0xFFFFFF", 0)
                ITSALIVE := IsBossChestAlive()

                ;Debug("Chest: " TrueFalseToString(ITSALIVE) " | Ultimate: " TrueFalseToString(SuccessfulUltiCheck) " | Ultimate: " TrueFalseToString(SuccessfulUtliCheck2))

                if (ITSALIVE) {
                    ;DoBossChest()
                    SendEvent("{R Down}{R Up}")
                } 
                window.LastChestCheckTick := A_TickCount
            }


            CustomPixelSearchAndHandlePets(window)

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

F8::ExitApp()  ; Exit the application
