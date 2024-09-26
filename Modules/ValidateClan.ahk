#Requires AutoHotkey v2.0
#SingleInstance Force

global Version := "1.0.2"
global Dependencies := ["Utils\Functions.ahk", "Utils\UWBOCRLib.ahk", "Utils\PS99Functions.ahk","Storage\PS99UI.ahk"]

#Include "%A_MyDocuments%\SOUP_Macros\Utils\Functions.ahk"
#Include "%A_MyDocuments%\SOUP_Macros\Utils\UWBOCRLib.ahk"
#Include "%A_MyDocuments%\SOUP_Macros\Utils\PS99Functions.ahk"
#Include "%A_MyDocuments%\SOUP_Macros\Storage\PS99UI.ahk"

CoordMode "Pixel", "Client"
CoordMode "Mouse", "Client"
SetMouseDelay -1


HasClanMenuOpen() {
    return UIPixelSearch("Clan_Button", "Clan_Button_Blue")[1]
}

OpenClanMenu() {
    if HasClanMenuOpen() {
        return true
    }
    startTick := A_TickCount
    Loop {
        if not HasClanMenuOpen() {
            ExitMenus()

            Sleep(300)
            SendEvent "{F Down}{F Up}"

            if not UIPixelSearchLoop("Clan_Button", "Clan_Button_Blue", 2000)[1] {
                continue
            }

            Sleep(200)

            UIClick("Clan_Button")
            return true
        }
    } Until A_TickCount - startTick >= 10000
    return false
}

GetClanName(name := "SOUP") {
    x1 := 388
    y1 := 171
    x2 := 533
    y2 := 233
    Bounds1 := RelativeXYToAbsolute(x1,y1)
    Bounds2 := RelativeXYToAbsolute(x2,y2)
    width := Bounds2.X - Bounds1.X
    height := Bounds2.Y - Bounds1.Y
    ocrResult := OCR.FromRect(Bounds1.X, Bounds1.Y, width, height, "en-us", 1)
    ExitMenus()
    if (RegExMatch(ocrResult.Text, name)) {
        return true
    }
    return false
}

ValidateClan(clanName := "") {
    if OpenClanMenu() {
        Sleep(500)
        x1 := 54
        y1 := 146
        x2 := 228
        y2 := 365
        Bounds1 := RelativeXYToAbsolute(x1,y1)
        Bounds2 := RelativeXYToAbsolute(x2,y2)
        width := Bounds2.X - Bounds1.X
        height := Bounds2.Y - Bounds1.Y
        ocrResult := OCR.FromRect(Bounds1.X, Bounds1.Y, width, height, "en-us", 1)

        if (RegExMatch(ocrResult.Text, "Invites|invite|vite|ites")) {
        ;if (not HasNotificationOpen("Hatch|hatch|atch|hat|ha|ch|set|tin|tings")) {
            ExitMenus()
            return false
        }

        if clanName != "" {
            Sleep(500)
            return GetClanName(clanName)
        }

        ExitMenus()
        return true
    }
}