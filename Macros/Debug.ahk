#Requires AutoHotkey v2.0
#SingleInstance Force

#Include "%A_MyDocuments%\SOUP_Macros\Utils\PS99_UI_Positions.ahk"

#Include "%A_MyDocuments%\SOUP_Macros\Utils\UWBOCRLib.ahk"

#Include "%A_MyDocuments%\SOUP_Macros\Modules\TeleportToWorld.ahk"
#Include "%A_MyDocuments%\SOUP_Macros\Modules\TeleportToZone.ahk"

#Include "%A_MyDocuments%\SOUP_Macros\Modules\Reconnect.ahk"
#Include "%A_MyDocuments%\SOUP_Macros\Modules\UseItem.ahk"
#Include "%A_MyDocuments%\SOUP_Macros\Modules\Autofarm.ahk"
#Include "%A_MyDocuments%\SOUP_Macros\Modules\SuperComputer.ahk"

#Include "%A_MyDocuments%\SOUP_Macros\Modules\MoveHumanoid.ahk"


; D 800
; S 1000

RouteMap := Map()
RouteMap["CatchPets"] := [
    {Key: "Q"},
    {Rest: 100},
    {Key: "D", Duration: 800},
    ;{Key: "W", Action: "Down", Duration: 500},
    {Rest: 2000},
    {Key: "S", Duration: 600},
    {Rest: 1000},
    {Key: "Q"},
    {Key: "WheelDown", Repeat: 5, Delay: 200}
]

CatchMacroPositions := Map()
CatchMacroPositions["DPSCounter"] := {Position: [24, 205], Bounds: [[385,284], [458,309]], Color: 0xFF564A, Variation: 5}


PixelSearchBuilder2(Name := "") {
    if (not CatchMacroPositions.Has(Name)) {
        return false
    }

    UI_Info := CatchMacroPositions[Name]

    VariationBuilder := UI_Info.Variation || 1
    BoundsBuilder := [[1, 1], [1, 1]]
    
    if (UI_Info.Bounds) {
        if (UI_Info.Bounds.Length == 2) {
            BoundsBuilder := UI_Info.Bounds
        } else {
            BoundsBuilder := [
                [UI_Info.Bounds[1], UI_Info.Bounds[2]],
                [UI_Info.Bounds[1], UI_Info.Bounds[2]]
            ]
        }
    }
       
    Success := PixelSearch(&x, &y, BoundsBuilder[1][1], BoundsBuilder[1][2], BoundsBuilder[2][1], BoundsBuilder[2][2], UI_Info.Color, VariationBuilder)
    
    if Success {
        return Success
    }

    return false
}

ChestIsAlive() {
    BoundsToAbsolute := UIBoundsToAbsoluteWH("", CatchMacroPositions["DPSCounter"])
    ocrResult := OCR.FromRect(BoundsToAbsolute[1], BoundsToAbsolute[2], BoundsToAbsolute[3], BoundsToAbsolute[4], "en-us", 1) ;OCR.FromWindow("Roblox", "en-us", 1, 1)

    if (ocrResult.Text != "") {
        return true
    } else {
        return PixelSearchBuilder2("DPSCounter")
    }
}

F3::{
    TeleportToWorld("Teleport_World2")
    TeleportToWorld("Teleport_World3")
    TeleportToZone("Elemental Realm", 5000)
    SolveMovement(RouteMap["CatchPets"])


    ;TeleportToZone("Elemental Realm", 5000)

    ;if (not InZone) {
    ;    TeleportToZone("_Spawn", 5000)
    ;    TeleportToZone("Elemental Realm", 5000)
    ;}




    ;Loop 5 {
    ;    SendEvent "{WheelDown}"
    ;    Sleep(200)
    ;}

    ;MsgBox(ChestIsAlive())


    
    /**EnableAutofarm()

    HighlightUI("Menu_Name")
    BoundsToAbsolute := UIBoundsToAbsoluteWH("Menu_Name")
    ocrResult := OCR.FromRect(BoundsToAbsolute[1], BoundsToAbsolute[2], BoundsToAbsolute[3], BoundsToAbsolute[4], "en-us", 1) ;OCR.FromWindow("Roblox", "en-us", 1, 1)

    OutputDebug(RegExMatch("[!kInventory!!]", "inv|tory"))
    **/

    ;OpenSupercomputer()
    ;SendInput("{Z Up}{Z Down}{Z Up}")

    ;MsgBox ocrResult.Text
}