#Requires AutoHotkey v2.0
#SingleInstance Force

global Version := "1.0.3"
global Dependencies := ["Utils\Functions.ahk","Utils\PS99Functions.ahk","Storage\PS99UI.ahk"]

#Include "%A_MyDocuments%\SOUP_Macros\Utils\Functions.ahk"
#Include "%A_MyDocuments%\SOUP_Macros\Utils\PS99Functions.ahk"
#Include "%A_MyDocuments%\SOUP_Macros\Storage\PS99UI.ahk"

CoordMode "Pixel", "Client"
CoordMode "Mouse", "Client"
SetMouseDelay -1

TeleportToZone(ZoneName := "", SleepDuration := 7000) {
    SuccessfulTeleport := false
    SendMode("Event")

    Loop {
        ExitMenus()
        Sleep(200)

        FoundTeleportButton := UIPixelSearchLoop("HUD_Teleport_Button_Red", "HUD_Teleport_Button_Red")[1]
        if (not FoundTeleportButton) {
            Debug("DIDNT FIND TELEPORT BUTTON")
            continue
        }

        UIClick("HUD_Teleport_Button")

        TeleportMenuIsOpen := UIPixelSearchLoop("Teleport_World2", "Teleport_World2")[1]
        if (not TeleportMenuIsOpen) {
            Debug("DIDNT FIND SPAWN WORLD")
            continue
        }

        Sleep(200)
        if (ZoneName == "_Spawn") {
            Debug("Teleporting to spawn area")
            UIClick("Teleport_Spawn")
        } else {
            Debug("Teleporting to " ZoneName)
            UIClick("Search_Box")
            Sleep(200)
            SendText(ZoneName)
            Sleep(100)
            UIClick("Teleport_Middle")
            Sleep(200)
        }

        ;if (UIPixelSearch("Notification_Cat", "Warning_Cat_Grey")) {
        if (_FindOops()) {
            Debug("Invalid teleport location")
            ExitMenus()
            Sleep(300)
            TeleportToZone("_Spawn", 5000)
            continue
        }

        ;UIPixelSearchLoop("HUD_Teleport_Button_Red", "HUD_Teleport_Button_Red")
        Sleep(500)


        EasyTeleport := false
        StartTick := A_TickCount
        Loop {
            TeleportButtonExists := UIPixelSearch("HUD_Teleport_Button_Red", "HUD_Teleport_Button_Red")[1]
            if (EasyTeleport = false) {
                if (not TeleportButtonExists) {
                    Debug("EASY TELEPORT DETECTION")
                    EasyTeleport := true
                }
            } else {
                if (TeleportButtonExists) {
                    SuccessfulTeleport := true
                    Debug("TELEPORT COMPLETED")
                    break
                }
            }

            if (A_TickCount - StartTick >= SleepDuration) {
                SuccessfulTeleport := true
                Debug("TELEPORT COMPLETED")
                break
            }
        }
        break
    }
    return SuccessfulTeleport
}
