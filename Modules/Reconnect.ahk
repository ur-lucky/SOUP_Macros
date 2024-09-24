#Requires AutoHotkey v2.0
#SingleInstance Force

global Version := "1.0.1"
global Dependencies := []

CoordMode "Pixel", "Client"
CoordMode "Mouse", "Client"

ReconnectPositionMap := Map()

ReconnectPositionMap["Reconnect_Button"] := {Position: [494,387], Bounds: [[409,372],[576,401]], Color: 0xFFFFFF, Variation: 3}
ReconnectPositionMap["Reconnect_Background"] := {Position: [405,300], Bounds: [[204,180],[595,420]], Color: 0x393B3D, Variation: 3}

ReconnectPositionMap["Escape_Button"] := {Position: [32,18], Bounds: [[26,11],[38,25]], Color: 0x9BA9B6, Variation: 3}

PixelSearchBuilder(Name := "") {
    if (not ReconnectPositionMap.Has(Name)) {
        return false
    }

    UI_Info := ReconnectPositionMap[Name]

    VariationBuilder := UI_Info.Variation || 1
    BoundsBuilder := [[1, 1], [1, 1]]
    
    if (UI_Info.Bounds) {
        if (UI_Info.Bounds.Length == 2) {
            BoundsBuilder := UI_Info.Bounds
        } else {
            BoundsBuilder := [
                [UI_Info.Bounds[1], UI_Info.Bounds[2]],
                [UI_Info.Bounds[1], UI_Info.Bounds[2]]
            ]
        }
    }
       
    Success := PixelSearch(&x, &y, BoundsBuilder[1][1], BoundsBuilder[1][2], BoundsBuilder[2][1], BoundsBuilder[2][2], UI_Info.Color, VariationBuilder)
    
    if Success {
        return Success
    }

    return false
}

ReconnectToRoblox() {
    ReconnectButton := ReconnectPositionMap["Reconnect_Button"]
    Loop {
        if IsUserDisconnected() {
            Loop {
                Sleep(50)
                SendEvent "{Click," ReconnectButton.Position[1] "," ReconnectButton.Position[2] "," 1 "}"
            } Until A_Index > 5
        }
        Success := false

        Loop {
            if (PixelSearchBuilder("Escape_Button")) {
                Success := true
                break
            }
            Sleep(100)
        } Until A_Index >= 100

        if (Success) {
            break
        }
    }
}

IsUserDisconnected() {
    if (PixelSearchBuilder("Reconnect_Background") && PixelSearchBuilder("Reconnect_Button") && not PixelSearchBuilder("Escape_Button")) {
        return true
    }
    return false
}

ReconnectCheck() {
    if (IsUserDisconnected()) {
        ReconnectToRoblox()
    }
}
