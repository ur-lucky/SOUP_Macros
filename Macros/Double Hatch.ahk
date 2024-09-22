#Requires AutoHotkey v2.0

#Include "%A_MyDocuments%\SOUP_Macros\Utils\Functions.ahk"
#Include "%A_MyDocuments%\SOUP_Macros\Utils\PS99_UI_Positions.ahk"

CoordMode "Pixel", "Client"
CoordMode "Mouse", "Client"
SetMouseDelay -1

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

F3::RunningState(true)
F5::RunningState(false)

F8::ExitApp


Loop {
    if (isRunning = true) {

        Loop {
            Click_UI("EggBuyMax", 1)
        } Until A_Index >= 20

        StartTick := A_TickCount

        Loop {
            Sleep(10)
            SendEvent "{Click, 400, 10}"
            SendEvent "{E Down}{E Up}"
            if (UISearch("EggBuyMax")) {
                break
            }
        } Until A_TickCount - StartTick >= 3000
    }
    Sleep(20)
}
