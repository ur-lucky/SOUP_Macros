#Requires AutoHotkey v2.0
#SingleInstance Force

global MacroName := "Pet Cube"
global MacroDescription := "Automatically break boss chest and capture pets"
global MacroStatus := "Stable"

global Version := "1.0.3"
global Dependencies := [
    "Utils\UWBOCRLib.ahk","Utils\Functions.ahk","Utils\PS99Functions.ahk","Storage\PS99UI.ahk",
    "Modules\Autofarm.ahk","Modules\MoveHumanoid.ahk","Modules\TeleportToWorld.ahk","Modules\TeleportToZone.ahk"
]

#Include "%A_MyDocuments%\SOUP_Macros\Utils\UWBOCRLib.ahk"
#Include "%A_MyDocuments%\SOUP_Macros\Utils\Functions.ahk"
#Include "%A_MyDocuments%\SOUP_Macros\Utils\PS99Functions.ahk"
#Include "%A_MyDocuments%\SOUP_Macros\Storage\PS99UI.ahk"

#Include "%A_MyDocuments%\SOUP_Macros\Modules\Autofarm.ahk"
#Include "%A_MyDocuments%\SOUP_Macros\Modules\MoveHumanoid.ahk"
#Include "%A_MyDocuments%\SOUP_Macros\Modules\TeleportToWorld.ahk"
#Include "%A_MyDocuments%\SOUP_Macros\Modules\TeleportToZone.ahk"

CoordMode "Pixel", "Client"
CoordMode "Mouse", "Client"
SetMouseDelay -1

global isRunning := false
global ClickCoordinatesPolygon := [{X: 185, Y: 53}, {X: 605, Y: 53}, {X: 605, Y: 200}, {X: 185, Y: 200}]



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
    return not PixelSearch(&outX, &outY, 735, 447, 785, 465, "0x765848", 20)
}


CustomPixelSearch(color, variation) {
    foundPixel := PixelSearch(&foundX, &foundY, ClickCoordinatesPolygon[1].X, ClickCoordinatesPolygon[1].Y, ClickCoordinatesPolygon[3].X, ClickCoordinatesPolygon[3].Y, color, variation)
    if foundPixel {
        if UIPixelSearch("Notification_Close", "Exit")[1] {
            UIClick("Notification_Yes")
            Sleep(200)
        } else {
            SendEvent("{Click " foundX " " foundY " 1}")
            Sleep(50)
            if UIPixelSearch("Notification_Close", "Exit")[1] {
                UIClick("Notification_Yes")
            }
        }
    }
}

global isRunning := false

F3:: { ;_RunAutoCatchMacro()
    global isRunning
    Debug("MACRO FUNCTION CALLED")

    if (isRunning) {
        Debug("MACRO ALREADY RUNNING")
        return
    }
    isRunning := true
    WinMove(,,816,638,"A")
    DrawPolygon(ClickCoordinatesPolygon, 0, "ff0000", 2, true)

    LastChestCheckTick := A_TickCount

    Loop {
        ; check for boss chest
        if (A_TickCount - LastChestCheckTick > 1000) {
            if (IsBossChestAlive()) {
                SendEvent("{R Down}{R Up}")
            } 
            LastChestCheckTick := A_TickCount
        }

        ; Search for pets
        CustomPixelSearch("0x2D4B54", 20)
        CustomPixelSearch("0x000000", 40)
        CustomPixelSearch("0xFB6408", 60)
        CustomPixelSearch("0xfbd608", 60)
        CustomPixelSearch("0x556BA7", 60)
        CustomPixelSearch("0xDC74FF", 60)
        CustomPixelSearch("0xbd34eb", 60)

        Sleep(10)
    }
}

F5:: Pause -1

F8::ExitApp()