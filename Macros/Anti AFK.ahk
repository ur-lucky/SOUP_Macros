#Requires Autohotkey v2
#SingleInstance Force

global MacroName := "Anti AFK"
global MacroDescription := "Prevents ROBLOX 20 minute idle kick"
global MacroStatus := "Stable"

global Version := "1.0.0"

global LastAntiIdle := 0

Enable_Checkbox() {
    global LastAntiIdle := 0
    AFKGui_Checkbox.Value := 1
}

Disable_Checkbox() {
    AFKGui_Checkbox.Value := 0
    AFKGui_Information.Text := "Not running"
}

Handle_Event() {
    isEnabled := (AFKGui_Checkbox.Value = 1)
    if isEnabled {
        Enable_Checkbox()
    } else {
        Disable_Checkbox()
    }
}

AFKGui := Gui(Options := "+AlwaysOnTop", Title := "Anti AFK")

AFKGui_Checkbox := AFKGui.AddCheckbox("x8 y5 w50 h15", "Active")
AFKGui_Checkbox.OnEvent("Click", (*) => Handle_Event())

AFKGui_Spacer1 := AFKGui.AddText("x60 y5 w2 h20 +0x1 +0x10")
AFKGui_Spacer2 := AFKGui.AddText("x150 y5 w2 h20 +0x1 +0x10")


AFKGui_Information := AFKGui.AddText("x68 y5 w70 h15 +0x200", "Not running")
AFKGui_Credit := AFKGui.AddText("x160 y5 w55 h15 +0x200", "SOUP Clan")

AFKGui.Show("w240 h25")

Loop {
    isEnabled := (AFKGui_Checkbox.Value = 1)
    if isEnabled {
        currentTick := A_TickCount
        if (currentTick - LastAntiIdle) > 900000 {
            BlockInput("On")

            LastAntiIdle := currentTick
            lastActiveWindow := WinGetPID("ahk_id" WinExist("A"))

            for _, hwnd in WinGetList("ahk_exe RobloxPlayerBeta.exe") {
                pid := WinGetPID("ahk_id" hwnd)
                WinActivate("ahk_pid" pid)
                WinWaitActive("ahk_pid" pid)
                Sleep(25)
                SendEvent("{LControl Down} {LControl Up}")
                Sleep(25)
            }
            WinActivate("ahk_pid" lastActiveWindow)
            BlockInput("Off")
        }
        AFKGui_Information.Text := "Anti idle in " Round(((LastAntiIdle + 900000) - currentTick) / 1000, 1)
    }
    Sleep(100)
}

F3::Enable_Checkbox()
F5::Disable_Checkbox()
F8::ExitApp()