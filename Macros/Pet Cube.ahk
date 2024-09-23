#Requires AutoHotkey v2.0
#SingleInstance Force

global MacroName := "Pet Cube"
global MacroDescription := "Automatically break boss chest and capture pets"
global MacroStatus := "Stable"

global Version := "1.0.0"
global Dependencies := [
    "Utils\UWBOCRLib.ahk","Utils\Functions.ahk","Utils\PS99Functions.ahk","Storage\PS99UI.ahk",
    "Modules\Autofarm.ahk","Modules\Autohatch.ahk","Modules\MoveHumanoid.ahk","Modules\TeleportToWorld.ahk","Modules\TeleportToZone.ahk"
]

#Include "%A_MyDocuments%\SOUP_Macros\Utils\UWBOCRLib.ahk"
#Include "%A_MyDocuments%\SOUP_Macros\Utils\Functions.ahk"
#Include "%A_MyDocuments%\SOUP_Macros\Utils\PS99Functions.ahk"
#Include "%A_MyDocuments%\SOUP_Macros\Storage\PS99UI.ahk"

#Include "%A_MyDocuments%\SOUP_Macros\Modules\Autofarm.ahk"
#Include "%A_MyDocuments%\SOUP_Macros\Modules\Autohatch.ahk"
#Include "%A_MyDocuments%\SOUP_Macros\Modules\MoveHumanoid.ahk"
#Include "%A_MyDocuments%\SOUP_Macros\Modules\TeleportToWorld.ahk"
#Include "%A_MyDocuments%\SOUP_Macros\Modules\TeleportToZone.ahk"

CoordMode "Pixel", "Client"
CoordMode "Mouse", "Client"
SetMouseDelay -1

global isRunning := false
global ClickCoordinatesPolygon := [{X: 525, Y: 239}, {X: 760, Y: 239}, {X: 678, Y: 315}]
global MovementMap := Map()

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


_RunAutoCatchMacro() {
    global isRunning
    Debug("MACRO FUNCTION CALLED")

    if (isRunning) {
        Debug("MACRO ALREADY RUNNING")
        return
    }

    isRunning := true

    DrawPolygon(ClickCoordinatesPolygon, 0, "ff0000", 2, true)

    currentTick := A_TickCount

    LastUltimateUseTick := currentTick
    LastChestCheckTick := currentTick

    CurrentSessionStartTick := 0

    one_hour := 60 * 60 * 1000

    ; this is what keeps it going
    Loop {
        currentTick := A_TickCount

        ; initialization
        SetupCharacter()
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


            ; only need to check every 5 seconds
            if (A_TickCount - LastChestCheckTick > 5000) {
                if (BossChestIsActive()) {
                    ; don't need to do a pixel search or check for time
                    SendEvent("{R Down}{R Up}")
                } 
                LastChestCheckTick := A_TickCount
            }

            ; click on random position inside polygon
            RandomMousePosition := RandomPositionInShape(ClickCoordinatesPolygon)
            SendEvent("{Click " RandomMousePosition.X " " RandomMousePosition.Y "}")

            Sleep(10)

            ; check for green button in notification menu (could be shitty)
            if (UIPixelSearch("Notification_Yes", "Accept")[1]) {
                UIClick("Notification_Yes")
                LastCatchPrompt := A_TickCount
                Sleep(750)
            } else {
                ;ExitMenus()
                ;Sleep(300)
            }

            ; if you havnt caught something in 5 minutes, lowkey skill issue
            if (A_TickCount - LastCatchPrompt > 300000) {
                ; escape loop to "rejoin"
                break
            }

            if (A_TickCount - CurrentSessionStartTick > one_hour) {
                ; escape loop to "rejoin"
                break
            }

        }
    }
}

F3::_RunAutoCatchMacro()

F5:: Pause -1

F8::ExitApp()