#Requires AutoHotkey v2.0
#SingleInstance Force

global Version := "1.0.0"
global Dependencies := [
    "Utils\UWBOCRLib.ahk","Utils\Functions.ahk","Utils\PS99Functions.ahk","Storage\PS99UI.ahk",
    "Modules\Autofarm.ahk","Modules\MoveHumanoid.ahk","Modules\Reconnect.ahk","Modules\TeleportToWorld.ahk","Modules\TeleportToZone.ahk"
]

#Include "%A_MyDocuments%\SOUP_Macros\Utils\UWBOCRLib.ahk"
#Include "%A_MyDocuments%\SOUP_Macros\Utils\Functions.ahk"
#Include "%A_MyDocuments%\SOUP_Macros\Utils\PS99Functions.ahk"
#Include "%A_MyDocuments%\SOUP_Macros\Storage\PS99UI.ahk"

#Include "%A_MyDocuments%\SOUP_Macros\Modules\Autofarm.ahk"
#Include "%A_MyDocuments%\SOUP_Macros\Modules\MoveHumanoid.ahk"
#Include "%A_MyDocuments%\SOUP_Macros\Modules\Reconnect.ahk"
#Include "%A_MyDocuments%\SOUP_Macros\Modules\TeleportToWorld.ahk"
#Include "%A_MyDocuments%\SOUP_Macros\Modules\TeleportToZone.ahk"

CoordMode "Pixel", "Client"
CoordMode "Mouse", "Client"
SetMouseDelay -1

global initialized := false
global MovementMap := Map()
global windows := []

MovementMap["BossChest"] := [
    {Key: "Q"},
    {Rest: 100},
    {Key: "D", Duration: 850},
    {Rest: 1000},
    {Key: "S", Duration: 300},
    {Rest: 400},
    ;{Func: EnableAutofarm},
    {Rest: 300},
    {Key: "S", Duration: 300},
    {Rest: 200},
    {Key: "Q"},
    {Key: "WheelDown", Repeat: 15, Delay: 200}
]

BossChestDPSCheck() {
    x1 := 335
    y1 := 243
    x2 := 430
    y2 := 280
    Bounds1 := RelativeXYToAbsolute(x1,y1)
    Bounds2 := RelativeXYToAbsolute(x2,y2)
    width := Bounds2.X - Bounds1.X
    height := Bounds2.Y - Bounds1.Y
    ocrResult := OCR.FromRect(Bounds1.X, Bounds1.Y, width, height, "en-us", 1)

    ;Debug("DPS OCR '" ocrResult.Text "' is not blank " TrueFalseToString(ocrResult.Text != ""))

    ;if (RegExMatch(ocrResult.Text, "DPS") > 0) {
    if (ocrResult.Text != "") {
        return true
    }
    return false
}

BossChestBroken() {
    x1 := 310
    y1 := 280
    x2 := 500
    y2 := 330
    Bounds1 := RelativeXYToAbsolute(x1,y1)
    Bounds2 := RelativeXYToAbsolute(x2,y2)
    width := Bounds2.X - Bounds1.X
    height := Bounds2.Y - Bounds1.Y
    ocrResult := OCR.FromRect(Bounds1.X, Bounds1.Y, width, height, "en-us", 1)

    ;Debug("Respawn OCR" ocrResult.Text)

    if (RegExMatch(ocrResult.Text, "Respawn|espawn|spawn") > 0) {
        return true
    }
    return false
}

IsBossChestCorrupted() {
    return PixelSearch(&outX, &outY, 350, 200, 416, 216, "0x252525", 10)
}

;0x765848
;0xD12800
;0X7A5A49
;290, 370, 450, 410
IsBossChestAlive() {
    ;return not PixelSearch(&outX, &outY, 350, 200, 416, 216, "0xA6FEFF", 20)
    return not PixelSearch(&outX, &outY, 290, 370, 470, 420, "0x765848", 2)
}

CreateUI(hwnd) {
    MainGui := Gui("+AlwaysOnTop -SysMenu +OwnDialogs +Parent" hwnd, "Chest Breaker")
    MainGui.OnEvent("Close", (*) => ExitApp())
    
    TabArray := ["Main", "Settings", "Chest Settings"]
    TabControl := MainGui.AddTab3("x0 y-1 w300 h200 -Wrap", TabArray)

    ; defaults to first tab, only putting here for readability
    TabControl.UseTab("Main")
    MainGui.AddText("w300 h30 x0 y20 +Center", "Chest Macro").SetFont("s16 Bold q4", "Cascadia Code")
    MainGui.AddText("w300 h120 x0 y50 +Center", "Automatically breaks chest`r`n`r`n[Controls] `r`nF3: Start`r`nF5: Pause`r`nF8: Stop").SetFont("s11 Bold q4", "Cascadia Code")
    
    ;MainGui.AddButton("w100 h25 x100 y170 +Center", "SOUP Clan").SetFont("s11 Bold q4", "Cascadia Code")


    TabControl.UseTab("Settings")
    ;MainGui.AddText("w300 h30 x0 y20 +Center", "Settings").SetFont("s16 Bold q4", "Cascadia Code")
    MainGui.AddCheckbox("x10 y30 vAntiAFK Checked1", "Anti AFK")
    MainGui.AddCheckbox("x10 y50 vHasAutofarm Checked" HasAutofarm(), "Autofarm")
    
    TabControl.UseTab("Chest Settings")
    ;MainGui.AddText("w300 h30 x0 y20 +Center", "Chest Settings").SetFont("s16 Bold q4", "Cascadia Code")
    MainGui.AddCheckbox("x10 y30 vIsBreakingChest Checked0", "Break Chest")
    MainGui.AddCheckbox("x10 y50 vUsingCorruption Checked0", "Using Corruption")
    MainGui.AddCheckbox("x10 y70 vChestRejoin Checked0", "Fast Chest Respawn")
    
    MainGui.Show("w300 h200 xCenter")
    return MainGui
}

RegisterWindow(hwnd, isBreaking := false) {
    pid := WinGetPID("ahk_id" hwnd)
    WinActivate("ahk_id" hwnd)
    ;
    ;   0x40000 removes resizing border
    ;   0x10000 removes maximize button
    ;
    WinSetStyle("-0x40000", "ahk_id" hwnd)
    WinSetStyle("-0x10000", "ahk_id" hwnd)
    WinMove(,,816, 638, "ahk_id" hwnd)

    windowGui := CreateUI(hwnd)

    runningGui := Gui()
    runningGui.Opt("+LastFound +AlwaysOnTop -Caption +ToolWindow +Parent" . hwnd)
    runningGui.BackColor := "FFFFFF"
    WinSetTransColor("FFFFFF 255", runningGui)
    runningGui.SetFont("c0x000000 s18 w600")
    infoText := runningGui.AddText("w600 h30 Center", "test")
    
    runningGui.Show("y-15")

    windowInfo := {
        Hwnd: hwnd,
        PID: pid,
        windowGui: windowGui,
        runningGui: runningGui,
        BossChecksFailed: 0,
        BossChecksSuccess: 0,
        LastAntiAFK: 0,
        IsRunning: false,
        IsPositioned: false,
        WaitingForChest: true,
        ChestFound: false,
        ChestDead: true
    }

    windows.Push(windowInfo)
}

for hwnd in WinGetList("ahk_exe RobloxPlayerBeta.exe") {
    RegisterWindow(hwnd, true)
}

Loop {
    global windows
    for index, window in windows {
        if !WinExist("ahk_id " window.Hwnd) {
            windows.RemoveAt(index)
            continue
        }

        if window.IsRunning = false {
            Sleep(100)
            continue
        }

        WinActivate("ahk_id" window.Hwnd)
        WinWaitActive("ahk_id" window.Hwnd)

        if IsUserDisconnected() {
            ReconnectToRoblox()
            UIPixelSearchLoop("HUD_Teleport_Button_Red", "HUD_Teleport_Button_Red", 60000)
            continue
        }

        if (window.windowGui["AntiAFK"].Value = true) && (A_TickCount - window.LastAntiAFK >= 300000) {
            Loop 5 {
                SendEvent("{Click 2 2}")
                Sleep(30)
            }
            window.LastAntiAFK := A_TickCount
        }

        if window.windowGui["IsBreakingChest"].Value = true {
            if window.IsPositioned = false {
                TeleportToWorld("Teleport_World1")
                TeleportToWorld("Teleport_World3")
                TeleportToZone("Elemental Realm", 10000)
                newMap := MovementMap["BossChest"].Clone()

                if window.windowGui["HasAutofarm"].Value = true {
                    Debug("HAS AUTOFARM")
                    newMap.InsertAt(6, {Func: EnableAutofarm})
                }

                SolveMovement(newMap)
                window.IsPositioned := true
            }


            ;if (BossChestDPSCheck()) {

            if (IsBossChestAlive()) {
                window.BossChecksFailed := 0
                if window.ChestDead {
                    window.ChestFound := true
                    window.ChestDead := false
                }
                if window.ChestFound {
                    Loop 20 {
                        SendEvent("{Click 370 380}")
                        Sleep(20)
                    }
                    if (window.windowGui["UsingCorruption"].Value = true) {
                        if IsBossChestCorrupted() = false {
                            Debug("NOT CORRUPTED")
                            continue
                        }
                        Debug("CHEST IS CORRUPTED")
                    }
                    
                    Debug("ULT")
                    SendEvent("{R Down}{R Up}")
                }
            } else {
                Debug("CHEST IS DEAD " window.BossChecksFailed)
                ;if BossChestBroken() {
                ;    window.BossChecksFailed := 100
                ;    Debug("FOUND RESPAWN TEXT")
                ;}
                window.BossChecksFailed += 1
                if window.BossChecksFailed >= 10 {
                    window.ChestDead := true
                    if window.ChestFound && window.windowGui["ChestRejoin"].Value = true {
                        window.IsPositioned := false
                        Debug("REJOINING")
                    }
                    window.ChestFound := false
                }
            }

            /*
            if (IsBossChestAlive()) {
                Loop 20 {
                    SendEvent("{Click 370 380}")
                    Sleep(20)
                }
                window.BossChecksSuccess += 1
                Debug("CHEST FOUND")
                if window.BossChecksSuccess >= 3 {
                    Debug("BOSS CHEST IS HERE 100%%")
                    if window.WaitingForChest {
                        window.WaitingForChest := false
                        window.ChestFound := true
                    }
                    window.BossChecksFailed := 0
                    if (window.windowGui["UsingCorruption"].Value = true) {
                        if IsBossChestCorrupted() = false {
                            Debug("NOT CORRUPTED")
                            continue
                        }
                        Debug("CHEST IS CORRUPTED")
                    }
                    
                    SendEvent("{R Down}{R Up}")
                }
            } else {
                Debug("NO CHEST FOUND")
                window.BossChecksFailed += 1
                if window.BossChecksFailed >= 3 && window.windowGui["ChestRejoin"].Value = true && window.ChestFound = true {
                    window.BossChecksSuccess := 0
                    window.IsPositioned := false
                    window.WaitingForChest := true
                    window.ChestFound := false
                }
            }
            /*
            isStillAlive := BossChestDPSCheck()
            Debug("CHEST ALIVE: " TrueFalseToString(isStillAlive))

            if window.WaitingForChest = true {
                if isStillAlive {
                    Debug("CHEST IS ALIVE, WAITING FOR IT TO BE DESTROYED")
                    window.WaitingForChest := false
                    window.ChestFound := true
                }
            } else {
                if window.ChestFound = true {
                    if isStillAlive = false {
                        Debug("CHEST HAS BEEN DESTROYED")
                        if window.windowGui["ChestRejoin"].Value = true {
                            window.IsPositioned := false
                        }
                    }

                    Loop 20 {
                        SendEvent("{Click 370 380}")
                        Sleep(20)
                    }

                    if (window.windowGui["UsingCorruption"].Value = true) {
                        if IsBossChestCorrupted() = true {
                            SendEvent("{R Down}{R Up}")
                        }
                    } else {
                        SendEvent("{R Down}{R Up}")
                    }
                }
            }*/
        }
    }
}

ToggleState(state := "") {
    global windows
    global initialized
    if !initialized {
        initialized := true
    }

    for window in windows {
        if not state {
            state := !window.IsRunning
        }
        window.IsRunning := state
        if state {
            window.windowGui.Hide()
        } else {
            window.windowGui.Show()
        }
        ;window.CurrentSessionStartTick := A_TickCount
        window.LastCatchPrompt := A_TickCount
    }
}

F3::{
    ToggleState(true)
}

F5::{
    ;ToggleState()
    Pause -1
}

F8::ExitApp()