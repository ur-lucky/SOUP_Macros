#Requires AutoHotkey v2.0
#SingleInstance Force

global MacroName := "Pet Cube"
global MacroDescription := "Automatically break boss chest and capture pets"
global MacroStatus := "Stable"

global Version := "1.1.0"
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
global ClickCoordinatesPolygon := [{X: 525, Y: 239}, {X: 760, Y: 239}, {X: 678, Y: 315}]
global MovementMap := Map()

global mountedGuis := []
global focusDebounce := 250
global windows := []

MovementMap["CatchPetsEvent"] := [
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


RandomPositionInShape(CoordinatesArray) {
    ; Function to check if a point is inside a polygon using the ray-casting algorithm
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

    ; Determine bounding box of the polygon for efficient random point generation
    minX := CoordinatesArray[1].X, maxX := CoordinatesArray[1].X
    minY := CoordinatesArray[1].Y, maxY := CoordinatesArray[1].Y
    for point in CoordinatesArray {
        if point.X < minX
            minX := point.X
        if point.X > maxX
            maxX := point.X
        if point.Y < minY
            minY := point.Y
        if point.Y > maxY
            maxY := point.Y
    }

    ; Generate points inside the shape dynamically
    Loop {
        ; Generate a random point within the bounding box of the polygon
        RandomX := Random(minX, maxX)
        RandomY := Random(minY, maxY)


        ; Check if the random point is inside the polygon
        if IsPointInsidePolygon(RandomX, RandomY, CoordinatesArray) {
            return {X: RandomX, Y: RandomY}
        }
    }
}


BossChestBroken() {
    x1 := 170
    y1 := 356
    x2 := 360
    y2 := 455
    Bounds1 := RelativeXYToAbsolute(x1,y1)
    Bounds2 := RelativeXYToAbsolute(x2,y2)
    width := Bounds2.X - Bounds1.X
    height := Bounds2.Y - Bounds1.Y
    ocrResult := OCR.FromRect(Bounds1.X, Bounds1.Y, width, height, "en-us", 1)

    ;Debug("Respawn OCR" ocrResult.Text)

    if (RegExMatch(ocrResult.Text, "Respawn|espawn|spawn") > 0) {
        return true
    }
    return false
}

BossChestDPSCheck() {
    x1 := 215
    y1 := 320
    x2 := 310
    y2 := 370
    Bounds1 := RelativeXYToAbsolute(x1,y1)
    Bounds2 := RelativeXYToAbsolute(x2,y2)
    width := Bounds2.X - Bounds1.X
    height := Bounds2.Y - Bounds1.Y
    ocrResult := OCR.FromRect(Bounds1.X, Bounds1.Y, width, height, "en-us", 1)

    ;Debug("DPS OCR" ocrResult.Text)

    if (RegExMatch(ocrResult.Text, "DPS") > 0) {
        return true
    }
    return false
}


BossChestIsActive() {
    FoundRespawnText := BossChestBroken()
    FoundDPSText := BossChestDPSCheck()

    Debug("FOUND DPS TEXT " TrueFalseToString(FoundDPSText) " FOUND RESPAWN TEXT" TrueFalseToString(FoundDPSText))

    if (FoundDPSText == true && FoundRespawnText == false) {
        return true
    }
    return false
}

IsBossChestAlive() {
    isDead := PixelSearch(&outX, &outY, 155, 500, 160, 505, "0x765848", 20)
    return not isDead
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

SetupCharacter() {
    TeleportToWorld("Teleport_World1")
    TeleportToWorld("Teleport_World3")
    TeleportToZone("Elemental Realm")
    SolveMovement(MovementMap["CatchPetsEvent"])
}


; OCR TEST
; X: {170, Y: 356} {X: 360 Y: 455}



; BOSS CHEST
; X: 158, Y: 502

;"0x765848"


; OLD COORDS
; {X: 760, Y: 370}

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
    ; Get initial window R
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


_RunAutoCatchMacro() {
    
    global isRunning
    Debug("MACRO FUNCTION CALLED")
    
    if (isRunning) {
        Debug("MACRO ALREADY RUNNING")
        return
    }
    
    isRunning := true
    hwnd := WinGetID("A")
    WinMove(,,816,638,"ahk_id" hwnd)

    windows.Push({
        Hwnd: hwnd, 
        LastChestCheckTick: A_TickCount,
        LastPetCaught: A_TickCount,
        OutOfCubesTick: 0,
        IsRunning: false,
        LastFocusTime: 0  ; Initialize LastFocusTime
    })

    guis := DrawPolygon(ClickCoordinatesPolygon, 0, "ff0000", 2, true)
    mountGuiToWindow(hwnd, guis)

    currentTick := A_TickCount

    LastUltimateUseTick := currentTick
    LastChestCheckTick := currentTick

    CurrentSessionStartTick := 0

    one_hour := 60 * 60 * 1000

    ; this is what keeps it going
    Loop {
        currentTick := A_TickCount

        ; initialization

        ;TeleportToWorld("Teleport_World1")
        ;TeleportToWorld("Teleport_World3")

        if not ValidateClan() {
            continue
        }


        TeleportToZone("Elemental Realm")
        SolveMovement(MovementMap["CatchPetsEvent"])

        ;SetupCharacter()

        CurrentSessionStartTick := A_TickCount
        LastCatchPrompt := A_TickCount

        ; main loop - this can be broken if something is just not working
        Loop {
            ; go by order of priority
            ; 1. Boss Chest
            ; --Check if chest is alive
            ; -- Attempt to use ultimate
            ; 2. Click on random position
            ; 3. Check for notication menu
            ; -- search for green button
            ; # THIS COULD BE BAD - WORKING AS OF NOW

            if IsUserDisconnected() {
                ReconnectToRoblox()
                UIPixelSearchLoop("HUD_Teleport_Button_Red", "HUD_Teleport_Button_Red")
                break
            }

            ; only need to check every 5 seconds
            if (A_TickCount - LastChestCheckTick > 1000) {
                if (IsBossChestAlive()) {
                    ; don't need to do a pixel search or check for time
                    SendEvent("{R Down}{R Up}")
                } 
                LastChestCheckTick := A_TickCount
            }

            ; click on random position inside polygon

            Loop 3 {
                RandomMousePosition := RandomPositionInShape(ClickCoordinatesPolygon)
                SendEvent("{Click " RandomMousePosition.X " " RandomMousePosition.Y " 2}")
            }

            if UIPixelSearchLoop("Notification_Close", "Exit", 0)[1] {
                buttonToClick := CheckNotification()
                Debug("BUTTON TO CLICK: " buttonToClick)
                if buttonToClick {
                    if buttonToClick = "Notification_Yes" {
                        UIClick(buttonToClick)
                    } else if buttonToClick = "Notification_Ok" {
                        UIClick(buttonToClick)
                    } else {
                        UIClick(buttonToClick)
                    }
                    LastCatchPrompt := A_TickCount
                }
            }

            ; if you havnt caught something in 5 minutes, lowkey skill issue
            if (A_TickCount - LastCatchPrompt > 300000) {
                ; escape loop to "rejoin"
                break
            }

            if (A_TickCount - CurrentSessionStartTick > (one_hour * 2)) {
                ; escape loop to "rejoin"
                break
            }
            Sleep(10)
        }
    }
}



; robloxInstanceHwnd := WinGetID("ahk_exe RobloxPlayerBeta.exe")
; WinActivate("ahk_id" robloxInstanceHwnd)
; WinMove(,,816, 638, "ahk_id" robloxInstanceHwnd)
; WinWaitActive("ahk_id" robloxInstanceHwnd)

; guis := DrawPolygon(ClickCoordinatesPolygon, 0, "ff0000", 2, true)
; mountGuiToWindow(robloxInstanceHwnd, guis)

; global one_hour := 60 * 60 * 1000

; Loop {
;     TeleportToWorld("Teleport_World1")
;     TeleportToWorld("Teleport_World3")

;     if not ValidateClan() {
;         continue
;     }

;     TeleportToZone("Elemental Realm")
;     SolveMovement(MovementMap["CatchPetsEvent"])

;     CurrentSessionStartTick := A_TickCount
;     LastPetCaught := A_TickCount
;     LastChestCheckTick := A_TickCount
;     OutOfCubesTick := 0

;     ; main loop - this can be broken if something is just not working
;     Loop {
;         ; go by order of priority
;         ; 1. Boss Chest
;         ; --Check if chest is alive
;         ; -- Attempt to use ultimate
;         ; 2. Click on random position
;         ; 3. Check for notication menu
;         ; -- search for green button
;         ; # THIS COULD BE BAD - WORKING AS OF NOW

;         if IsUserDisconnected() {
;             ReconnectToRoblox()
;             UIPixelSearchLoop("HUD_Teleport_Button_Red", "HUD_Teleport_Button_Red")
;             break
;         }

;         ; only need to check every 5 seconds
;         if (A_TickCount - LastChestCheckTick > 1000) {
;             if (IsBossChestAlive()) {
;                 ; don't need to do a pixel search or check for time
;                 SendEvent("{R Down}{R Up}")
;             } 
;             LastChestCheckTick := A_TickCount
;         }

;         if (A_TickCount - LastPetCaught > 300000) {
;             ; if the player doesnt catch a pet within 5 minutes, rejoin
;             ; escape loop to "rejoin"
;             break
;         }

;         if (A_TickCount - CurrentSessionStartTick > (one_hour * 2)) {
;             ; rejoin every 2 hours to prevent lag
;             ; escape loop to "rejoin"
;             break
;         }

;         ; click on random position inside polygon

;         Loop 3 {
;             RandomMousePosition := RandomPositionInShape(ClickCoordinatesPolygon)
;             SendEvent("{Click " RandomMousePosition.X " " RandomMousePosition.Y " 2}")
;         }

;         if UIPixelSearchLoop("Notification_Close", "Exit", 0)[1] {
;             buttonToClick := CheckNotification()
;             Debug("BUTTON TO CLICK: " buttonToClick)
;             if buttonToClick {
;                 if buttonToClick = "Notification_Yes" {
;                     UIClick(buttonToClick)
;                     LastPetCaught := A_TickCount
;                 } else if buttonToClick = "Notification_Ok" {
;                     UIClick(buttonToClick)
;                     OutOfCubesTick := A_TickCount
;                 } else {
;                     UIClick(buttonToClick)
;                 }
;             }
;         }

;         ; if you havnt caught something in 5 minutes, lowkey skill issue
;         Sleep(10)
;     }
; }

F3::_RunAutoCatchMacro()

F5:: Pause -1

F8::ExitApp()