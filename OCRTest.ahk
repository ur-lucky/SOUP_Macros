#Requires AutoHotkey v2.0
#SingleInstance Force

#Include "%A_ScriptDir%\Utils\"
#Include "UWBOCRLib.ahk"

CoordMode "Pixel", "Client"
CoordMode "Mouse", "Client"

RelativeXYToAbsolute(X := 0, Y := 0) {
    ;Debug("Passed X: " X)
    WinGetPos(&absoluteX, &absoluteY, &width, &height, "A")
    return {X: absoluteX + X + 6, Y: absoluteY + Y + 31}
}

Bounds1 := RelativeXYToAbsolute(70,84)
Bounds2 := RelativeXYToAbsolute(360,130)

width := Bounds2.X - Bounds1.X
height := Bounds2.Y - Bounds1.Y

F4::{
    start := A_TickCount
    ocrResult := OCR.FromRect(Bounds1.X, Bounds1.Y, width, height, "en-us", 1) ;OCR.FromWindow("Roblox", "en-us", 1, 1)
    MsgBox("FOUND TEXT: " ocrResult.Text " | TOOK " A_TickCount - start)
}