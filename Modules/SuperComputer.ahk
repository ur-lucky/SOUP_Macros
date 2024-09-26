#Requires AutoHotkey v2.0
#SingleInstance Force

global Version := "1.0.0"
global Dependencies := ["Utils\Functions.ahk","Utils\PS99Functions.ahk","Storage\PS99UI.ahk"]

#Include "%A_MyDocuments%\SOUP_Macros\Utils\Functions.ahk"
#Include "%A_MyDocuments%\SOUP_Macros\Utils\PS99Functions.ahk"
#Include "%A_MyDocuments%\SOUP_Macros\Storage\PS99UI.ahk"

CoordMode "Pixel", "Client"
CoordMode "Mouse", "Client"

_HasSupercomputerOpen() {
    return HasMenuOpen("Super|super|comp|uter")
}

_Scroll(scrollPosition := 0, buttonIndexInRow := 1, secondRow := false) {
    UIClick("Menu_Scroll")
    Sleep(100)
    SendMode("Event")

    ; Reset scrolling to the top (scrolling up)
    Loop 20 {
        SendEvent("{WheelUp}")
        Sleep(10)
    }

    ; Correct for top offset
    Sleep(20)
    SendEvent("{Click Down}")
    Sleep(20)
    MouseMove(0, 11, 300, "R")
    Sleep(20)
    SendEvent("{Click Up}")

    ; Scroll down according to scrollPosition
    if (scrollPosition > 0) {
        Sleep(20)
        SendEvent("{Click Down}")
        Sleep(20)
        MouseMove(0, 65 * scrollPosition, 300, "R")
        Sleep(20)
        SendEvent("{Click Up}")
    }
    Sleep(100)
    ; Click the specific button based on the index within the row
    ; Adjust MouseMove based on whether the button is on the second row
    yPos := secondRow ? 385 : 225  ; If secondRow is true, use 385, else 225
    ;MouseMove(125 + ((buttonIndexInRow - 1) * 50), yPos, 1) ; Adjust coordinates as needed
    SendEvent("{Click " 126 + ((buttonIndexInRow - 1) * 50) " " yPos "}")
    Sleep(5)
    SendEvent("{Click " 125 + ((buttonIndexInRow - 1) * 50) " " yPos "}")
}

ClickButton(buttonNumber) {
    ; Determine the scroll position and the button's position in the row
    scrollPosition := Floor((buttonNumber - 1) / 5) ; Scroll position (0 for 1-5, 1 for 6-10, etc.)
    buttonIndexInRow := Mod(buttonNumber - 1, 5) + 1 ; Button's index within the row (1-5)
    
    ; If the button number is between 21-25, scroll to position 3 but click the second row
    secondRow := false
    if (buttonNumber >= 21 && buttonNumber <= 25) {
        scrollPosition := 3
        secondRow := true  ; Indicate that the button is on the second row (y position 385)
        buttonIndexInRow := buttonNumber - 20 ; Adjust the index for the second row
    }

    _Scroll(scrollPosition, buttonIndexInRow, secondRow)
}

OpenSupercomputer() {
    Loop {
        isOpen := _HasSupercomputerOpen()
        if (not isOpen) {
            ExitMenus()
            Sleep(100)
            UIClick("HUD_SuperComputer_Button")
            Sleep(100)
        } else {
            break
        }
    }
    ClickButton(21)
}
