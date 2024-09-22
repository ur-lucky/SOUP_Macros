#Requires AutoHotkey v2.0
#SingleInstance Force

/*
#Include "%A_MyDocuments%\SOUP_Macros\Utils\PS99_UI_Positions.ahk"
#Include "%A_MyDocuments%\SOUP_Macros\Utils\Functions.ahk"

CoordMode "Pixel", "Client"
CoordMode "Mouse", "Client"

HasInventoryOpen() {
    return UISearch("Items_Button")
}

OpenItems() {
    Loop {
        if (not HasInventoryOpen()) {
            CloseAllMenus()
            SendEvent "{F Down}{F Up}"

            if (not UISearchLoop("Items_Button")[1]) {
                continue
            }

            ClickUI("Items_Button")
            break
        }
        break
    }
}

UseItem(ItemName := "", Amount := 1, ItemUseDelay := 70) {
    AmountRemaining := Amount
    Loop {
        OutputDebug("Opening inventory")
        OpenItems()
        ClickUI("Search_Button")
        OutputDebug("Searching for item")
        Sleep(300)
        SendText(ItemName)
        Sleep(100)
        StartTick := A_TickCount
        Loop {
            if (AmountRemaining <= 0 || A_TickCount - StartTick > 500) {
                break
            }
            ClickUI("First_Item")
            AmountRemaining -= 1
            OutputDebug("Used item!" AmountRemaining "left!")
            Sleep(ItemUseDelay)
        }

        if (AmountRemaining <= 0) {
            break
        }
    }
}*/
