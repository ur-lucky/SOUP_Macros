#Requires AutoHotkey v2.0
#SingleInstance Force

#Include "%A_MyDocuments%\SOUP_Macros\Utils\Functions.ahk"
#Include "%A_MyDocuments%\SOUP_Macros\Utils\PS99Functions.ahk"
#Include "%A_MyDocuments%\SOUP_Macros\Storage\PS99UI.ahk"

CoordMode "Pixel", "Client"
CoordMode "Mouse", "Client"
SetMouseDelay -1

TeleportToWorld(WorldName := "") {
    if (not PS99_UI_POSITION_MAP.Has(WorldName)) {
        Error("Invalid world name" WorldName)
        return false
    }

    SuccessfulTeleport := false
    SendMode("Event")

    Loop {
        AlreadyInMenu := UIPixelSearch("Teleport_World2", "Teleport_World2")[1]

        if (not AlreadyInMenu) {
            ExitMenus()
            Sleep(200)
            
            FoundTeleportButton := UIPixelSearchLoop("HUD_Teleport_Button_Red", "HUD_Teleport_Button_Red")[1]
            DrawPolygonOnUI("HUD_Teleport_Button_Red", 500)

            Debug("Found button: " TrueFalseToString(FoundTeleportButton))

            if (not FoundTeleportButton) {
                Debug("COULDN'T FIND TELEPORT BUTTON... RETRYING " A_Index)
                continue
            }
            
            UIClick("HUD_Teleport_Button")
            Debug("CLICKING TELEPORT BUTTON")


            TeleportMenuIsOpen := UIPixelSearchLoop("Teleport_World2", "Teleport_World2")[1]
            if (not TeleportMenuIsOpen) {
                Debug("TELEPORT MENU NOT OPEN... RETRYING")
                continue
            }
        }
        Sleep(500)


        UIClick(WorldName)
        Debug("CLICKING ON " WorldName)

        Sleep(500)

        Debug("INITIATING TELEPORT")

        if (UIPixelSearch("Notification_Yes", "Accept")) {
            UIClick("Notification_Yes")
        }

        if (_FindOops()) {
            Debug("Invalid world location")
            ExitMenus()
            Sleep(300)
            break
        }

        ;} else {
         ;   if (UIPixelSearch("Notification_Cat", "Warning_Cat_Grey")[1]) {
         ;       ExitMenus()
         ;       Debug("ERROR CAT FOUND... BREAKING")
          ;      Sleep(500)
          ;      break
          ;  }
        ;}


        Sleep(2000)

        SuccessfulTeleport := UIPixelSearchLoop("HUD_Teleport_Button_Red", "HUD_Teleport_Button_Red", 60000)[1]
        
        if (not SuccessfulTeleport) {
            Debug("DIDNT FIND TELEPORT BUTTON")
            continue
        }
        
        Debug("FOUND TELEPORT BUTTON")
        Sleep(500)
        SendEvent "{Tab Down}{Tab Up}"

        SuccessfulTeleport := true
        break
    }

    return SuccessfulTeleport
}
