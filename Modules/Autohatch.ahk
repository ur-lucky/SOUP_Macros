#Requires AutoHotkey v2.0
#SingleInstance Force

global Version := "1"
global Dependencies := ["Utils\Functions.ahk", "Utils\UWBOCRLib.ahk", "Utils\PS99Functions.ahk","Storage\PS99UI.ahk"]

#Include "%A_MyDocuments%\SOUP_Macros\Utils\Functions.ahk"
#Include "%A_MyDocuments%\SOUP_Macros\Utils\UWBOCRLib.ahk"
#Include "%A_MyDocuments%\SOUP_Macros\Utils\PS99Functions.ahk"
#Include "%A_MyDocuments%\SOUP_Macros\Storage\PS99UI.ahk"

CoordMode "Pixel", "Client"
CoordMode "Mouse", "Client"
SetMouseDelay -1

_AutohatchEnabled() {
    return UIPixelSearch("HUD_AutoHatch_Button_Toggle", "Enabled")[1]
}

_AutohatchDisabled() {
   return UIPixelSearch("HUD_AutoHatch_Button_Toggle", "Disabled")[1]
}

_ButtonEnabled(ButtonName := "HatchSettings_Autohatch_Toggle") {
    return UIPixelSearch(ButtonName, "Enabled")[1]
}

_ButtonDisabled(ButtonName := "HatchSettings_Autohatch_Toggle") {
    return UIPixelSearch(ButtonName, "Disabled")[1]
}

_InitialCheck() {
    Opened := OpenHatchSettings()
    if (_ButtonEnabled("HatchSettings_Autohatch_Toggle")) {
        UIClick("HatchSettings_Autohatch_Toggle")
        HideMouse()
    }
}

OpenHatchSettings() {
    Loop 5 {
        x1 := 219
        y1 := 163
        x2 := 403
        y2 := 197
        Bounds1 := RelativeXYToAbsolute(x1,y1)
        Bounds2 := RelativeXYToAbsolute(x2,y2)
        width := Bounds2.X - Bounds1.X
        height := Bounds2.Y - Bounds1.Y
        ocrResult := OCR.FromRect(Bounds1.X, Bounds1.Y, width, height, "en-us", 1)

        if (not RegExMatch(ocrResult.Text, "Auto|auto|hatch|hat")) {
        ;if (not HasNotificationOpen("Hatch|hatch|atch|hat|ha|ch|set|tin|tings")) {
            ExitMenus()
            Sleep(200)
            UIClick("HUD_AutoHatch_Button")
            HideMouse()
            Sleep(300)
        } else {
            return true
        }
    }
    return false
}

DisableAutohatch() {
    Opened := OpenHatchSettings()
    if (_ButtonEnabled("HatchSettings_Autohatch_Toggle")) {
        UIClick("HatchSettings_Autohatch_Toggle")
        HideMouse()
        return true
    }
    return false
}

EnableAutohatch() {
    OpenHatchSettings()
    ;if (_ButtonEnabled("HatchSettings_Autohatch_Toggle")) {
    ;    Disabled := DisableAutohatch()
    ;    Sleep(100)
    ;}
    if (_ButtonDisabled("HatchSettings_Autohatch_Toggle")) {
        UIClick("HatchSettings_Autohatch_Toggle")
        HideMouse()
    }
}
