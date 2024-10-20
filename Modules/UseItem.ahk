#Requires AutoHotkey v2.0
#SingleInstance Force

global Version := "1.0.0"
global Dependencies := ["Utils\PS99Functions.ahk","Storage\PS99UI.ahk"]

#Include "%A_MyDocuments%\SOUP_Macros\Utils\PS99Functions.ahk"
#Include "%A_MyDocuments%\SOUP_Macros\Storage\PS99UI.ahk"

CoordMode "Pixel", "Client"
CoordMode "Mouse", "Client"

HasInventoryOpen() {
    local foundItems := UIPixelSearch("Items_Button", "Items_Button")[1]
    local foundClanButton := UIPixelSearch("Clan_Button", "Clan_Button_Blue")[1]
    local foundInventoryWhite := PixelSearch(&ux, &uy, 3, 183, 6, 186, "0xFFFFFF", 1)
    return foundItems && foundClanButton && foundInventoryWhite
}

OpenItems() {
    Loop {
        if !HasInventoryOpen() {
            ExitMenus()
            SendEvent "{F Down}{F Up}"

            if (not UIPixelSearchLoop("Items_Button")[1]) {
                continue
            }

            UIClick("Items_Button")
            break
        }
        break
    }
}

UseItem(ItemName := "", Amount := 1, ItemUseDelay := 70) {
    AmountRemaining := Amount
    Loop {
        Debug("Opening inventory")
        OpenItems()
        Sleep(400)
        UIClick("Items_Button")
        Sleep(300)
        UIClick("Search_Box")
        Debug("Searching for item")
        Sleep(200)
        SendText(ItemName)
        Sleep(100)
        StartTick := A_TickCount
        Loop {
            if (AmountRemaining <= 0 || A_TickCount - StartTick > 500) {
                break
            }
            UIClick("First_Item")
            AmountRemaining -= 1
            Debug("Used item!" AmountRemaining "left!")
            Sleep(ItemUseDelay)
        }

        if (AmountRemaining <= 0) {
            break
        }
    }
}
