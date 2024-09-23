#Requires AutoHotkey v2.0

global Version := "1"
global Dependencies := ["Utils\Functions.ahk","Utils\PS99Functions.ahk","Storage\PS99UI.ahk"]

#Include "%A_MyDocuments%\SOUP_Macros\Utils\Functions.ahk"
#Include "%A_MyDocuments%\SOUP_Macros\Utils\PS99_UI_Positions.ahk"
#Include "%A_MyDocuments%\SOUP_Macros\Utils\UWBOCRLib.ahk"


CoordMode "Pixel", "Client"
CoordMode "Mouse", "Client"

global isRunning := false

RunningState(state:=!isRunning) {
    if state = false {
        global isRunning := false
    } else {
        global isRunning := true
        roblox_hwnd := WinGetID("ahk_exe RobloxPlayerBeta.exe")
        roblox_pid := WinGetPID("ahk_id" roblox_hwnd)
        WinActivate "ahk_pid" roblox_pid
        WinMove(,,816,638,"ahk_pid " roblox_pid)
    }
}

MoveClick(x, y) {
    MouseMove(x-1, y-1)
    Sleep(10)
    MouseMove(x+1, y-1)
    Sleep(10)
    SendEvent "{Click," x "," y "}"
}

F3::RunningState(true)
F5::RunningState(false)

F8::ExitApp

Loop {
    if (isRunning = true) {
        if (UISearch("Notification_Close") == true) {
            Click_UI("Notification_Close")
        }

        if (UISearch("Spinny_Wheel_Spin") == true) {
            Sleep(100)
            UIPosition := Get_UI("Spinny_Wheel_Top").Position
            OutputDebug("X " UIPosition[1] " Y " UIPosition[2])
            CurrentColor := PixelGetColor(UIPosition[1], UIPosition[2])

            Click_UI("Spinny_Wheel_Spin")

            Loop {
                Sleep(10)
                if (PixelSearch(&x, &y, UIPosition[1], UIPosition[2], UIPosition[1], UIPosition[2], CurrentColor, 5) == 0) {
                    break
                }
            } Until A_Index >= 50 ;Until PixelSearch(&x, &y, UIPosition[1], UIPosition[2], UIPosition[1], UIPosition[2], CurrentColor, 5) == 0 || A_Index >= 50
            
            try {
                BoundsToAbsolute := UIBoundsToAbsoluteWH("Spinny_Wheel_Oops")
                ocrResult := OCR.FromRect(BoundsToAbsolute[1], BoundsToAbsolute[2], BoundsToAbsolute[3], BoundsToAbsolute[4], "en-us", 1) ;OCR.FromWindow("Roblox", "en-us", 1, 1)
        
                if (ocrResult.FindString("oops!")) {
                    MsgBox "FOUND OOPS"
                    RunningState(false)
                }
            }

            Click_UI("Menu_Close")
            UISearchLoop("Notification_Close", 5000)
        }
    }
    Sleep(20)
}
