#Requires AutoHotkey v2.0

#Include "%A_MyDocuments%\SOUP_Macros\Utils\Functions.ahk"
#Include "%A_MyDocuments%\SOUP_Macros\Utils\PS99_UI_Positions.ahk"
#Include "%A_MyDocuments%\SOUP_Macros\Utils\UWBOCRLib.ahk"
#Include "%A_MyDocuments%\SOUP_Macros\Utils\PS99_Keybinds.ahk"


CoordMode "Pixel", "Client"
CoordMode "Mouse", "Client"



FindSettingsText(TextToFind := "") {
    UIInfo := GetUI("Settings_Text_Frame")
    BoundsToAbsolute := UIBoundsToAbsoluteWH("Settings_Text_Frame")
    ocrResult := OCR.FromRect(BoundsToAbsolute[1], BoundsToAbsolute[2], BoundsToAbsolute[3], BoundsToAbsolute[4], "en-us", 1) ;OCR.FromWindow("Roblox", "en-us", 1, 1)

    SettingsMap := Map()

    for line in ocrResult.Lines {
        ;if word.Text == "Keybinds" {
            lineWidth := 0
            lineHeight := line.Words[1].h
            lineX := line.Words[1].x
            lineY := line.Words[1].y
            for word in line.Words {
                lineWidth += word.w
            }
            
            absoluteX := BoundsToAbsolute[1] + lineX
            absoluteY := BoundsToAbsolute[2] + lineY

            SettingsMap[line.Text] := {YPosition: UIInfo.Bounds[1][2] + lineY}
        ;}
    }

    if (SettingsMap[TextToFind]) {
        SendEvent "{Click 520," SettingsMap[TextToFind].YPosition "}"
    }
}

F3::{
    WinMove(,,816,638,"A")

    CloseAllMenus()

    Sleep(300)

    SendEvent "{F Down}{F Up}"

    Sleep(1000)

    ClickUI("Settings_Menu", 1)

    Sleep(300)

    FindSettingsText("Keybinds")

    Sleep(500)

    UIInfo := GetUI("Keybind_Equals")
    BoundsToAbsolute := UIBoundsToAbsoluteWH("Keybind_Equals")
    ocrResult := OCR.FromRect(BoundsToAbsolute[1], BoundsToAbsolute[2], BoundsToAbsolute[3], BoundsToAbsolute[4], "en-us", 1) ;OCR.FromWindow("Roblox", "en-us", 1, 1)

    Highlight(BoundsToAbsolute[1], BoundsToAbsolute[2], BoundsToAbsolute[3], BoundsToAbsolute[4])

    KeybindArray := Array()

    MsgBox ocrResult.Text

    for line in ocrResult.Lines {
        ;if word.Text == "Keybinds" {
            lineWidth := 0
            lineHeight := line.Words[1].h
            lineX := line.Words[1].x
            lineY := line.Words[1].y
            for word in line.Words {
                lineWidth += word.w
            }
            
            OutputDebug(line.Text)
            
            absoluteX := BoundsToAbsolute[1] + lineX
            absoluteY := BoundsToAbsolute[2] + lineY


            KeybindArray.Push({YPosition: UIInfo.Bounds[1][2] + lineY})
        ;}
    }

    KeybindItemInfo := GetUI("Keybind_Item")

    for keybindDeletePos in KeybindArray {
        MouseMove(KeybindItemInfo.Position.X, keybindDeletePos.YPosition)
        Sleep(1000)
         ;SendEvent "{Click 520," SettingsMap[TextToFind].YPosition "}"
    }
}