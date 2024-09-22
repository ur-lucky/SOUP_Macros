#Requires AutoHotkey v2.0
#SingleInstance Force

#Include "%A_MyDocuments%\SOUP_Macros\Utils\Functions.ahk"
#Include "%A_MyDocuments%\SOUP_Macros\Utils\PS99Functions.ahk"
#Include "%A_MyDocuments%\SOUP_Macros\Storage\PS99UI.ahk"

CoordMode "Pixel", "Client"
CoordMode "Mouse", "Client"

_AutofarmEnabled() {
    return UIPixelSearch("HUD_AutoFarm_Button_Toggle", "Enabled")[1]
}

_AutofarmDisabled() {
    return UIPixelSearch("HUD_AutoFarm_Button_Toggle", "Disabled")[1]
}

HasAutofarm() {
    return (_AutofarmEnabled() || _AutofarmDisabled()) 
}

DisableAutofarm() {
    if (_AutofarmEnabled()) {
        UIClick("HUD_AutoFarm_Button")
        HideMouse()
        return true
    }
    return false
}

EnableAutofarm() {
    if (DisableAutofarm()) {
        Sleep(300)
    }
    UIClick("HUD_AutoFarm_Button")
    HideMouse()
}
