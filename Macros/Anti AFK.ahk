#Requires Autohotkey v2

; Creating the UI
TraySetIcon("shell32.dll","44") ; Set the icon
myGui := Gui()
myGui.Opt("+AlwaysOnTop") ; Set it so when window is active (not minimized), its always ontop
CheckBox1 := myGui.Add("CheckBox", "x8 y5 w50 h15", "Active")
Seperator1 := myGui.Add("Text", "x60 y5 w2 h20 +0x1 +0x10")
Text1 := myGui.Add("Text", "x68 y5 w130 h15 +0x200", "Currently not running")
Seperator2 := myGui.Add("Text", "x200 y5 w2 h20 +0x1 +0x10")
Text2 := myGui.Add("Text", "x210 y5 w55 h15 +0x200", "by ur_lucky")
CheckBox1.OnEvent("Click", OnEventHandler)
myGui.OnEvent('Close', (*) => ExitApp())
myGui.Title := "Anti-Idle"
myGui.Show("w270 h25")

lastAntiIdle := 0 ; Track the last time the game was interacted with

CheckCheckBox(*) { ; Changing state to true
    global lastAntiIdle := 0
    CheckBox1.value := 1
}

UncheckCheckBox(*) { ; Changing state to false
    Text1.text := "Currently not running"
    CheckBox1.value := 0
}

OnEventHandler(*) { ; Changing the state of the button
    if (CheckBox1.value = 0)
        UncheckCheckBox()
    else
        CheckCheckBox()
}

F3::CheckCheckBox()
F5::UncheckCheckBox()
F8::ExitApp


Loop ; Main loop
{
    if (CheckBox1.Value = 1){
        timeNow := A_TickCount/1000
        if (timeNow - lastAntiIdle > 900){
            BlockInput true ; If ran as administrator, blocks all keyboard/mouse inputs
            active_pid := WinGetPID("ahk_id" WinExist("A")) ; Save current open window to return to after anti idle
            lastAntiIdle := timeNow
            ids := WinGetList("ahk_exe RobloxPlayerBeta.exe") ; Get all ROBLOX instances open
            For each, hwnd in ids{
                pid := WinGetPID("ahk_id" hwnd)
                WinActivate "ahk_pid" pid
                WinWaitActive "ahk_pid" pid
                Sleep 50
                SendInput "{LCtrl down} {LCtrl up}"
                Sleep 50
            }
            WinActivate "ahk_pid" active_pid
            BlockInput false
        }
        difference := Round((lastAntiIdle + 900) - timeNow, 1)
        Text1.text := "Anti idle in " . difference ; Display anti idle time
    }
    Sleep 100
}return 